#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Department-aware generator for shift / personnel_shifts SQL.

What it enforces before writing SQL:
  - one shift row per department / date / shift_type
  - 3 doctors, 6 nurses, 2 administrative employees per shift
  - staff are selected only from departments they belong to
      * doctors: strictly by doctor_department.csv
      * nurses: by nurses.department_id
      * administrative staff: by administrative_personnel.department_id
  - monthly max shifts: doctors 15, nurses 20, administrative staff 25
  - no same employee in the same date+shift twice
  - no adjacent shifts according to the 8-hour-rest rule
  - no 3 consecutive night shifts
  - if a resident doctor is selected, the same shift also includes
    at least one doctor with rank Επιμελητής Α or Διευθυντής
"""

from __future__ import annotations

import argparse
import calendar
import csv
import itertools
import random
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Iterable

SHIFTS = ["ΠΡΩΙ", "ΑΠΟΓΕΥΜΑ", "ΝΥΧΤΑ"]

REQUIRED_PER_SHIFT = {
    "Ιατρός": 3,
    "Νοσηλευτής": 6,
    "Διοικητικό Προσωπικό": 2,
}

MONTHLY_LIMITS = {
    "Ιατρός": 15,
    "Νοσηλευτής": 20,
    "Διοικητικό Προσωπικό": 25,
}

SUPERVISOR_GRADES = {"Επιμελητής Α", "Διευθυντής"}
RESIDENT_GRADES = {"Ειδικευόμενος"}


@dataclass(frozen=True)
class StaffMember:
    personnel_id: int
    personnel_type: str
    department_ids: tuple[int, ...]
    rank: str | None = None
    specialty: str | None = None
    is_supervisor: bool = False
    is_resident: bool = False


@dataclass(frozen=True)
class ShiftKey:
    department_id: int
    shift_date: date
    shift_type: str


@dataclass(frozen=True)
class Department:
    department_id: int
    department_description: str


@dataclass
class BuildResult:
    staff: list[StaffMember]
    departments: dict[int, Department]
    warnings: list[str]


def parse_department_ids(text: str | None, all_ids: Iterable[int]) -> list[int]:
    """Parse e.g. '1,2,5-8' into [1,2,5,6,7,8]. If text is None, return all_ids."""
    if text is None or not text.strip():
        return sorted(set(all_ids))

    result: list[int] = []
    for part in text.split(','):
        part = part.strip()
        if not part:
            continue
        if '-' in part:
            start_s, end_s = part.split('-', 1)
            start, end = int(start_s), int(end_s)
            if end < start:
                raise ValueError(f"Bad range: {part}")
            result.extend(range(start, end + 1))
        else:
            result.append(int(part))
    result = sorted(set(result))
    if not result:
        raise ValueError("No department IDs were given.")
    return result


def parse_day_range(year: int, month: int, start_day: int | None, end_day: int | None) -> list[date]:
    max_day = calendar.monthrange(year, month)[1]
    s = 1 if start_day is None else start_day
    e = max_day if end_day is None else end_day
    if s < 1 or e > max_day or e < s:
        raise ValueError(f"Bad day range: {s}-{e} for {year}-{month:02d}")
    return [date(year, month, d) for d in range(s, e + 1)]


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open('r', encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError(f"{path} has no header row.")
        return [{k: (v or '').strip() for k, v in row.items()} for row in reader]


def read_personnel(path: Path) -> dict[int, str]:
    rows = read_csv_rows(path)
    required_cols = {"personnel_id", "personnel_type"}
    if rows:
        missing = required_cols - set(rows[0].keys())
        if missing:
            raise ValueError(f"personnel CSV is missing columns: {sorted(missing)}")

    data: dict[int, str] = {}
    for row in rows:
        pid = int(row["personnel_id"])
        ptype = row["personnel_type"]
        if ptype in REQUIRED_PER_SHIFT:
            data[pid] = ptype
    return data


def read_departments(path: Path) -> dict[int, Department]:
    rows = read_csv_rows(path)
    if rows:
        missing = {"department_id", "department_description"} - set(rows[0].keys())
        if missing:
            raise ValueError(f"departments CSV is missing columns: {sorted(missing)}")

    departments: dict[int, Department] = {}
    for row in rows:
        tid = int(row["department_id"])
        departments[tid] = Department(department_id=tid, department_description=row["department_description"])
    return departments


def read_doctor_department(path: Path, valid_dept_ids: set[int]) -> tuple[dict[int, tuple[int, ...]], list[str]]:
    rows = read_csv_rows(path)
    if rows:
        missing = {"doctor_id", "department_id"} - set(rows[0].keys())
        if missing:
            raise ValueError(f"doctor_department CSV is missing columns: {sorted(missing)}")

    memberships: dict[int, set[int]] = defaultdict(set)
    ignored_unknown: dict[int, int] = defaultdict(int)
    for row in rows:
        pid = int(row["doctor_id"])
        tid = int(row["department_id"])
        if tid in valid_dept_ids:
            memberships[pid].add(tid)
        else:
            ignored_unknown[tid] += 1

    warnings: list[str] = []
    if ignored_unknown:
        parts = ", ".join(f"department_id={tid}: {count}" for tid, count in sorted(ignored_unknown.items()))
        warnings.append(f"Some doctor_department rows were ignored (not in departments.csv): {parts}")

    return {pid: tuple(sorted(tids)) for pid, tids in memberships.items()}, warnings


def build_staff(
    personnel_csv: Path,
    doctors_csv: Path,
    doctor_dept_csv: Path,
    nurses_csv: Path,
    admin_csv: Path,
    departments_csv: Path,
) -> BuildResult:
    personnel = read_personnel(personnel_csv)
    departments = read_departments(departments_csv)
    valid_dept_ids = set(departments)
    warnings: list[str] = []

    doctor_departments, membership_warnings = read_doctor_department(doctor_dept_csv, valid_dept_ids)
    warnings.extend(membership_warnings)

    staff_by_id: dict[int, StaffMember] = {}

    # Process Doctors
    unmapped_doctors: dict[str, int] = defaultdict(int)
    for row in read_csv_rows(doctors_csv):
        missing = {"doctor_id", "specialty", "rank"} - set(row.keys())
        if missing:
            raise ValueError(f"doctors CSV is missing columns: {sorted(missing)}")
        pid = int(row["doctor_id"])
        if personnel.get(pid) != "Ιατρός":
            continue
        specialty = row["specialty"]
        rank = row["rank"]
        
        dept_ids = doctor_departments.get(pid, tuple())
        if not dept_ids:
            unmapped_doctors["no doctor_department row"] += 1
            continue
            
        staff_by_id[pid] = StaffMember(
            personnel_id=pid,
            personnel_type="Ιατρός",
            department_ids=dept_ids,
            rank=rank,
            specialty=specialty,
            is_supervisor=rank in SUPERVISOR_GRADES,
            is_resident=rank in RESIDENT_GRADES,
        )

    if unmapped_doctors:
        parts = ", ".join(f"{reason}={count}" for reason, count in sorted(unmapped_doctors.items()))
        warnings.append(f"Some doctors were ignored because they do not have a valid row in doctor_department.csv. Ignored: {parts}")

    # Process Nurses
    for row in read_csv_rows(nurses_csv):
        missing = {"nurse_id", "department_id"} - set(row.keys())
        if missing:
            raise ValueError(f"nurses CSV is missing columns: {sorted(missing)}")
        pid = int(row["nurse_id"])
        tid = int(row["department_id"])
        if personnel.get(pid) != "Νοσηλευτής" or tid not in valid_dept_ids:
            continue
        staff_by_id[pid] = StaffMember(
            personnel_id=pid,
            personnel_type="Νοσηλευτής",
            department_ids=(tid,),
        )

    # Process Admin
    for row in read_csv_rows(admin_csv):
        missing = {"admin_id", "department_id"} - set(row.keys())
        if missing:
            raise ValueError(f"administrative_personnel CSV is missing columns: {sorted(missing)}")
        pid = int(row["admin_id"])
        tid = int(row["department_id"])
        if personnel.get(pid) != "Διοικητικό Προσωπικό" or tid not in valid_dept_ids:
            continue
        staff_by_id[pid] = StaffMember(
            personnel_id=pid,
            personnel_type="Διοικητικό Προσωπικό",
            department_ids=(tid,),
        )

    return BuildResult(staff=sorted(staff_by_id.values(), key=lambda s: s.personnel_id), departments=departments, warnings=warnings)


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def date_sql(d: date) -> str:
    return f"DATE '{d.isoformat()}'"


def chunked(items: list, size: int) -> Iterable[list]:
    for i in range(0, len(items), size):
        yield items[i:i + size]


class Scheduler:
    def __init__(
        self,
        staff: list[StaffMember],
        departments: dict[int, Department],
        department_ids: list[int],
        days: list[date],
        seed: int,
        doctor_candidate_cap: int,
    ) -> None:
        self.staff = staff
        self.departments = departments
        self.department_ids = department_ids
        self.days = days
        self.rng = random.Random(seed)
        self.doctor_candidate_cap = doctor_candidate_cap

        self.by_type_dept: dict[str, dict[int, list[int]]] = {
            ptype: {tid: [] for tid in department_ids} for ptype in REQUIRED_PER_SHIFT
        }
        self.staff_type: dict[int, str] = {}
        self.is_supervisor: dict[int, bool] = {}
        self.is_resident: dict[int, bool] = {}
        self.rank_map: dict[int, str | None] = {}
        self.specialty: dict[int, str | None] = {}

        for s in staff:
            self.staff_type[s.personnel_id] = s.personnel_type
            self.is_supervisor[s.personnel_id] = s.is_supervisor
            self.is_resident[s.personnel_id] = s.is_resident
            self.rank_map[s.personnel_id] = s.rank
            self.specialty[s.personnel_id] = s.specialty
            for tid in s.department_ids:
                if tid in self.department_ids and s.personnel_type in self.by_type_dept:
                    self.by_type_dept[s.personnel_type][tid].append(s.personnel_id)

        all_ids = [s.personnel_id for s in staff]
        self.rng.shuffle(all_ids)
        self.ranking = {pid: i for i, pid in enumerate(all_ids)}
        for ptype in self.by_type_dept:
            for tid in self.by_type_dept[ptype]:
                self.rng.shuffle(self.by_type_dept[ptype][tid])

        self.assignments_by_person: dict[int, set[tuple[date, str]]] = defaultdict(set)
        self.monthly_load: dict[int, int] = defaultdict(int)
        self.night_load: dict[int, int] = defaultdict(int)
        self.assignments: dict[ShiftKey, list[int]] = {}

    def feasibility_report(self) -> tuple[bool, str]:
        total_shifts_per_department = len(self.days) * len(SHIFTS)
        lines: list[str] = []
        ok = True

        lines.append("Feasibility check by department")
        lines.append(f"Days: {self.days[0].isoformat()} to {self.days[-1].isoformat()} ({len(self.days)} days)")
        lines.append(f"Shifts per department: {total_shifts_per_department}")
        lines.append("")

        lines.append("Global capacity across selected departments")
        for ptype, required_count in REQUIRED_PER_SHIFT.items():
            unique_people = {
                pid
                for tid in self.department_ids
                for pid in self.by_type_dept[ptype][tid]
            }
            needed = len(self.department_ids) * total_shifts_per_department * required_count
            capacity = len(unique_people) * MONTHLY_LIMITS[ptype]
            status = "OK"
            details: list[str] = []
            if capacity < needed:
                ok = False
                status = "FAIL"
                details.append(f"monthly capacity {capacity} < needed {needed}")
            lines.append(
                f"  - {ptype}: unique_pool={len(unique_people)}, capacity={capacity}, needed={needed} -> {status}"
                + (f" ({'; '.join(details)})" if details else "")
            )
        lines.append("")

        for tid in self.department_ids:
            dept_name = self.departments.get(tid, Department(tid, f"department_id={tid}")).department_description
            lines.append(f"[{tid}] {dept_name}")
            for ptype, required_count in REQUIRED_PER_SHIFT.items():
                pool = self.by_type_dept[ptype][tid]
                needed = total_shifts_per_department * required_count
                capacity = len(pool) * MONTHLY_LIMITS[ptype]
                minimum_now = required_count
                status = "OK"
                details: list[str] = []
                if len(pool) < minimum_now:
                    ok = False
                    status = "FAIL"
                    details.append(f"need at least {minimum_now} available at the same time")
                if capacity < needed:
                    ok = False
                    status = "FAIL"
                    details.append(f"monthly capacity {capacity} < needed {needed}")
                lines.append(
                    f"  - {ptype}: pool={len(pool)}, capacity={capacity}, needed={needed} -> {status}"
                    + (f" ({'; '.join(details)})" if details else "")
                )

            doctors = self.by_type_dept["Ιατρός"][tid]
            residents = [p for p in doctors if self.is_resident.get(p, False)]
            supervisors = [p for p in doctors if self.is_supervisor.get(p, False)]
            other_non_residents = [
                p for p in doctors
                if not self.is_resident.get(p, False) and not self.is_supervisor.get(p, False)
            ]
            doctor_needed = total_shifts_per_department * REQUIRED_PER_SHIFT["Ιατρός"]
            supervisor_capacity = len(supervisors) * MONTHLY_LIMITS["Ιατρός"]
            resident_capacity = len(residents) * MONTHLY_LIMITS["Ιατρός"]
            other_non_resident_capacity = len(other_non_residents) * MONTHLY_LIMITS["Ιατρός"]
            non_resident_capacity = supervisor_capacity + other_non_resident_capacity
            min_resident_assignments_needed = max(0, doctor_needed - non_resident_capacity)
            max_resident_assignments_supported = min(
                resident_capacity,
                2 * min(supervisor_capacity, total_shifts_per_department),
            )
            if min_resident_assignments_needed > max_resident_assignments_supported:
                ok = False
                lines.append(
                    "    FAIL: doctor hierarchy capacity is insufficient. "
                    f"At least {min_resident_assignments_needed} resident assignments are needed, "
                    f"but at most {max_resident_assignments_supported} can be paired with a supervisor."
                )
            lines.append("")
        return ok, "\n".join(lines)

    def check_basic_feasibility(self) -> None:
        ok, report = self.feasibility_report()
        if not ok:
            raise RuntimeError(report)

    def violates_rest(self, pid: int, day: date, shift: str) -> bool:
        assigned = self.assignments_by_person[pid]
        if (day, shift) in assigned:
            return True

        if shift == "ΠΡΩΙ":
            if (day, "ΑΠΟΓΕΥΜΑ") in assigned: return True
            if (day - timedelta(days=1), "ΝΥΧΤΑ") in assigned: return True
        elif shift == "ΑΠΟΓΕΥΜΑ":
            if (day, "ΠΡΩΙ") in assigned: return True
            if (day, "ΝΥΧΤΑ") in assigned: return True
        elif shift == "ΝΥΧΤΑ":
            if (day, "ΑΠΟΓΕΥΜΑ") in assigned: return True
            if (day + timedelta(days=1), "ΠΡΩΙ") in assigned: return True
        return False

    def violates_consecutive_nights(self, pid: int, day: date, shift: str) -> bool:
        if shift != "ΝΥΧΤΑ":
            return False
        nights = {d for d, s in self.assignments_by_person[pid] if s == "ΝΥΧΤΑ"}
        nights.add(day)
        for start in (day - timedelta(days=2), day - timedelta(days=1), day):
            if all((start + timedelta(days=i)) in nights for i in range(3)):
                return True
        return False

    def eligible(self, pid: int, day: date, shift: str, already_selected: set[int]) -> bool:
        if pid in already_selected:
            return False
        ptype = self.staff_type[pid]
        if self.monthly_load[pid] >= MONTHLY_LIMITS[ptype]:
            return False
        if self.violates_rest(pid, day, shift):
            return False
        if self.violates_consecutive_nights(pid, day, shift):
            return False
        return True

    def candidate_score(self, pid: int) -> tuple[int, int, int]:
        return (self.monthly_load[pid], self.night_load[pid], self.ranking[pid])

    def select_one_from_pool(self, pool: list[int], day: date, shift: str, selected: set[int]) -> int:
        candidates = [pid for pid in pool if self.eligible(pid, day, shift, selected)]
        if not candidates:
            raise RuntimeError(f"No eligible staff in pool for {day} {shift}.")
        candidates.sort(key=self.candidate_score)
        return candidates[0]

    def valid_doctor_combo(self, combo: tuple[int, ...]) -> bool:
        has_resident = any(self.is_resident.get(pid, False) for pid in combo)
        has_supervisor = any(self.is_supervisor.get(pid, False) for pid in combo)
        return (not has_resident) or has_supervisor

    def doctor_combo_score(self, combo: tuple[int, ...], shift: str) -> tuple[int, int, int, int, int]:
        has_resident = any(self.is_resident.get(pid, False) for pid in combo)
        has_supervisor = any(self.is_supervisor.get(pid, False) for pid in combo)
        supervisor_without_resident_penalty = 1 if (has_supervisor and not has_resident) else 0
        load = sum(self.monthly_load[pid] for pid in combo)
        nights = sum(self.night_load[pid] for pid in combo)
        ranks = sum(self.ranking[pid] for pid in combo)
        resident_count = sum(1 for pid in combo if self.is_resident.get(pid, False))
        return (load, nights, supervisor_without_resident_penalty, resident_count, ranks)

    def select_doctors(self, department_id: int, day: date, shift: str, selected: set[int]) -> list[int]:
        pool = self.by_type_dept["Ιατρός"][department_id]
        candidates = [pid for pid in pool if self.eligible(pid, day, shift, selected)]
        if len(candidates) < REQUIRED_PER_SHIFT["Ιατρός"]:
            raise RuntimeError(
                f"Not enough eligible doctors for department_id={department_id} on {day} {shift}: "
                f"need {REQUIRED_PER_SHIFT['Ιατρός']}, have {len(candidates)}."
            )

        candidates.sort(key=self.candidate_score)
        caps = [min(len(candidates), self.doctor_candidate_cap)]
        if len(candidates) <= 90 and caps[0] != len(candidates):
            caps.append(len(candidates))
        caps = sorted(set(caps))

        best_combo: tuple[int, ...] | None = None
        best_score: tuple[int, int, int, int, int] | None = None
        for cap in caps:
            for combo in itertools.combinations(candidates[:cap], REQUIRED_PER_SHIFT["Ιατρός"]):
                if not self.valid_doctor_combo(combo):
                    continue
                score = self.doctor_combo_score(combo, shift)
                if best_score is None or score < best_score:
                    best_score = score
                    best_combo = combo
            if best_combo is not None:
                return list(best_combo)

        raise RuntimeError(
            f"No valid doctor combination for department_id={department_id} on {day} {shift}. "
            "A resident doctor needs an Επιμελητής Α or Διευθυντής in the same shift."
        )

    def add_assignment(self, pid: int, key: ShiftKey) -> None:
        self.assignments_by_person[pid].add((key.shift_date, key.shift_type))
        self.monthly_load[pid] += 1
        if key.shift_type == "ΝΥΧΤΑ":
            self.night_load[pid] += 1

    def schedule_shift(self, key: ShiftKey) -> None:
        selected: set[int] = set()
        shift_staff: list[int] = []

        doctors = self.select_doctors(key.department_id, key.shift_date, key.shift_type, selected)
        selected.update(doctors)
        shift_staff.extend(doctors)

        for ptype in ("Νοσηλευτής", "Διοικητικό Προσωπικό"):
            pool = self.by_type_dept[ptype][key.department_id]
            for _ in range(REQUIRED_PER_SHIFT[ptype]):
                pid = self.select_one_from_pool(pool, key.shift_date, key.shift_type, selected)
                selected.add(pid)
                shift_staff.append(pid)

        for pid in shift_staff:
            self.add_assignment(pid, key)
        self.assignments[key] = shift_staff

    def run(self) -> dict[ShiftKey, list[int]]:
        self.check_basic_feasibility()
        for d in self.days:
            for shift in SHIFTS:
                for department_id in self.department_ids:
                    self.schedule_shift(ShiftKey(department_id, d, shift))
        return self.assignments


def generate_sql(
    assignments: dict[ShiftKey, list[int]],
    delete_existing: bool = False,
    values_chunk_size: int = 5000,
) -> str:
    keys = sorted(assignments, key=lambda k: (k.shift_date, SHIFTS.index(k.shift_type), k.department_id))
    department_ids = sorted({k.department_id for k in keys})
    start_date = min(k.shift_date for k in keys)
    end_date = max(k.shift_date for k in keys)

    lines: list[str] = []
    lines.append("-- Generated SQL for shift / personnel_shifts")
    lines.append("-- Department-aware: staff were selected only from their department membership pools.")
    lines.append("-- Review before running on production data.")
    lines.append("BEGIN;")
    lines.append("")

    if delete_existing:
        dept_csv = ", ".join(str(x) for x in department_ids)
        lines.append("-- Delete existing shifts in the selected date range/departments, useful for reruns.")
        lines.append("DELETE FROM personnel_shifts ps")
        lines.append("USING shift s")
        lines.append("WHERE ps.shift_id = s.shift_id")
        lines.append(f"  AND s.department_id IN ({dept_csv})")
        lines.append(f"  AND s.shift_date BETWEEN {date_sql(start_date)} AND {date_sql(end_date)};")
        lines.append("")
        lines.append("DELETE FROM shift s")
        lines.append(f"WHERE s.department_id IN ({dept_csv})")
        lines.append(f"  AND s.shift_date BETWEEN {date_sql(start_date)} AND {date_sql(end_date)};")
        lines.append("")

    # Insert shifts
    for chunk in chunked(keys, values_chunk_size):
        lines.append("INSERT INTO shift (department_id, shift_date, shift_type, shift_status)")
        lines.append("VALUES")
        value_lines = [
            f"  ({k.department_id}, {date_sql(k.shift_date)}, {sql_quote(k.shift_type)}, 'DRAFT')"
            for k in chunk
        ]
        lines.append(",\n".join(value_lines))
        lines.append("ON CONFLICT (department_id, shift_date, shift_type) DO NOTHING;")
        lines.append("")

    # Prepare assignment rows
    assignment_rows: list[tuple[int, date, str, int]] = []
    for k in keys:
        for pid in assignments[k]:
            assignment_rows.append((k.department_id, k.shift_date, k.shift_type, pid))

    # Insert personnel shifts linking to the newly created shifts
    for chunk in chunked(assignment_rows, values_chunk_size):
        lines.append("INSERT INTO personnel_shifts (shift_id, personnel_id)")
        lines.append("SELECT s.shift_id, v.personnel_id")
        lines.append("FROM (VALUES")
        value_lines = [
            f"  ({dept_id}, {date_sql(d)}, {sql_quote(shift)}::type_shift_types, {pid})"
            for dept_id, d, shift, pid in chunk
        ]
        lines.append(",\n".join(value_lines))
        lines.append(") AS v(department_id, shift_date, shift_type, personnel_id)")
        lines.append("JOIN shift s")
        lines.append("  ON s.department_id = v.department_id")
        lines.append(" AND s.shift_date = v.shift_date")
        lines.append(" AND s.shift_type = v.shift_type;")
        lines.append("")

    # Update shift_status to COMPLETED
    for chunk in chunked(keys, values_chunk_size):
        lines.append("UPDATE shift s")
        lines.append("SET shift_status = 'COMPLETED'")
        lines.append("FROM (VALUES")
        value_lines = [
            f"  ({k.department_id}, {date_sql(k.shift_date)}, {sql_quote(k.shift_type)}::type_shift_types)"
            for k in chunk
        ]
        lines.append(",\n".join(value_lines))
        lines.append(") AS v(department_id, shift_date, shift_type)")
        lines.append("WHERE s.department_id = v.department_id")
        lines.append("  AND s.shift_date = v.shift_date")
        lines.append("  AND s.shift_type = v.shift_type")
        lines.append("  AND s.shift_status = 'DRAFT';")
        lines.append("")

    lines.append("COMMIT;")
    lines.append("")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate department-aware SQL for monthly hospital shifts.")
    parser.add_argument("--personnel-csv", required=True, type=Path, help="Path to personnel.csv")
    parser.add_argument("--doctors-csv", required=True, type=Path, help="Path to doctors.csv")
    parser.add_argument("--doctor-dept-csv", required=True, type=Path, help="Path to doctor_department.csv")
    parser.add_argument("--nurses-csv", required=True, type=Path, help="Path to nurses.csv")
    parser.add_argument("--admin-csv", required=True, type=Path, help="Path to administrative_personnel.csv")
    parser.add_argument("--departments-csv", required=True, type=Path, help="Path to departments.csv")
    parser.add_argument("--year", required=True, type=int, help="Year, e.g. 2026")
    parser.add_argument("--month", required=True, type=int, choices=range(1, 13), help="Month number 1-12")
    parser.add_argument("--start-day", type=int, default=None, help="Optional first day of month to generate")
    parser.add_argument("--end-day", type=int, default=None, help="Optional last day of month to generate")
    parser.add_argument("--departments", default=None, help="Department IDs, e.g. '1,2,3' or '1-17'. Default: all departments in departments.csv")
    parser.add_argument("--seed", type=int, default=42, help="Deterministic tie-break seed")
    parser.add_argument("--max-attempts", type=int, default=5, help="Retry scheduling with seed+attempt if greedy assignment gets stuck")
    parser.add_argument("--doctor-candidate-cap", type=int, default=45, help="How many eligible doctors to consider for 3-person combinations")
    parser.add_argument("--output", type=Path, default=None, help="Output .sql file; stdout if omitted")
    parser.add_argument("--delete-existing", action="store_true", help="Delete existing shift rows for this date range/departments before inserting")
    parser.add_argument("--check-only", action="store_true", help="Print feasibility report and exit without generating SQL")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    build = build_staff(
        personnel_csv=args.personnel_csv,
        doctors_csv=args.doctors_csv,
        doctor_dept_csv=args.doctor_dept_csv,
        nurses_csv=args.nurses_csv,
        admin_csv=args.admin_csv,
        departments_csv=args.departments_csv,
    )
    department_ids = parse_department_ids(args.departments, all_ids=build.departments.keys())
    unknown_dept = sorted(set(department_ids) - set(build.departments))
    if unknown_dept:
        raise RuntimeError(f"Unknown department IDs: {unknown_dept}")
    days = parse_day_range(args.year, args.month, args.start_day, args.end_day)

    scheduler_for_report = Scheduler(
        staff=build.staff,
        departments=build.departments,
        department_ids=department_ids,
        days=days,
        seed=args.seed,
        doctor_candidate_cap=args.doctor_candidate_cap,
    )
    ok, report = scheduler_for_report.feasibility_report()

    if args.check_only:
        for w in build.warnings:
            print(f"WARNING: {w}")
        print(report)
        return 0 if ok else 2

    if not ok:
        for w in build.warnings:
            print(f"WARNING: {w}", file=sys.stderr)
        print(report, file=sys.stderr)
        return 2

    last_error: Exception | None = None
    assignments: dict[ShiftKey, list[int]] | None = None
    used_seed = args.seed
    for attempt in range(max(1, args.max_attempts)):
        used_seed = args.seed + attempt
        scheduler = Scheduler(
            staff=build.staff,
            departments=build.departments,
            department_ids=department_ids,
            days=days,
            seed=used_seed,
            doctor_candidate_cap=args.doctor_candidate_cap,
        )
        try:
            assignments = scheduler.run()
            break
        except RuntimeError as exc:
            last_error = exc
            assignments = None

    if assignments is None:
        for w in build.warnings:
            print(f"WARNING: {w}", file=sys.stderr)
        print("Scheduling failed after retries.", file=sys.stderr)
        if last_error:
            print(str(last_error), file=sys.stderr)
        return 3

    sql = generate_sql(assignments, delete_existing=args.delete_existing)
    prefix_lines = [f"-- WARNING: {w}" for w in build.warnings]
    prefix_lines.append(f"-- Scheduler seed used: {used_seed}")
    sql = "\n".join(prefix_lines) + "\n" + sql

    if args.output:
        args.output.write_text(sql, encoding='utf-8')
        print(
            f"Wrote {args.output} "
            f"({len(assignments)} shift rows, {sum(len(v) for v in assignments.values())} personnel assignments)."
        )
    else:
        print(sql)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))