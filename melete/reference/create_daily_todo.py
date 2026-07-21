#!/usr/bin/env python3
"""Create today's BALTHASAR TODO note and carry work forward.

Sections:
  HOOK    - resume points, dropped mid-task. Carries to tomorrow's HOOK.
            Graduates to BACKLOG after HOOK_MAX_DAYS.
  TODO    - what the user chose for today. Never written by this script;
            promotion from BACKLOG is a human act. Unfinished items fall
            back to BACKLOG.
  HABITS  - template boilerplate. Never carried.
  BACKLOG - the standing pile. Carried daily. Reviewed fortnightly.

SLATED.md is a waiting room: a dated task MOVES out of it into BACKLOG on
its date. It is never copied - a task lives in exactly one place.

Idempotent: if today's note exists, this does nothing.
"""

import datetime
import os
import re
import sys

VAULT = os.path.expanduser("~/Magi")
FOLDER = os.path.join(VAULT, "02 ⯂ BALTHASAR", "BALTHASAR-26")
SLATED = os.path.join(VAULT, "02 ⯂ BALTHASAR", "SLATED.md")
TEMPLATE = os.path.join(VAULT, "08 • TEMPLATES", "01 Balthasar TODO Template.md")
CHANGELOG = os.path.join(VAULT, "11 • AGENT", "changelogs")

HOOK_MAX_DAYS = 3  # a hook that survives this long stopped being a resume point

# The day does not turn over at midnight. Work done at 01:00 belongs to the day
# that started yesterday morning, not to a new one. Everything downstream takes
# a date, so this is the only place the wall clock is consulted.
DAY_ROLLOVER_HOUR = 2

NOTE_RE = re.compile(r"^(\d{4}-\d{2}-\d{2}) TODO\.md$")
TASK_RE = re.compile(r"^(?P<ind>[\t ]*)- \[(?P<st>[ x/\-])\]\s+(?P<body>.*?)\s*$")
OPEN = (" ", "/")  # states that carry; [x] done and [-] cancelled do not


def logical_today():
    """Today, per the rollover hour - not per the calendar."""
    now = datetime.datetime.now()
    return (now - datetime.timedelta(hours=DAY_ROLLOVER_HOUR)).date()


def note_path(d):
    return os.path.join(FOLDER, f"{d} TODO.md")


def prior_note(today):
    """Most recent existing note before today - NOT literally yesterday.

    The notes have gaps. A literal-yesterday lookup finds nothing after a
    gap and silently drops the entire backlog.
    """
    dates = sorted(
        m.group(1) for m in (NOTE_RE.match(f) for f in os.listdir(FOLDER)) if m
    )
    prior = [d for d in dates if d < today.isoformat()]
    return prior[-1] if prior else None


def sections(path):
    """Parse a note into {heading: [raw lines]}."""
    out, cur = {}, None
    with open(path, encoding="utf-8") as fh:
        for line in fh.read().split("\n"):
            if line.startswith("## "):
                cur = line[3:].strip()
                out[cur] = []
            elif cur:
                out[cur].append(line)
    return out


def text_of(body):
    """The task's identity: its prose, with every field and marker stripped.

    Two lines with the same text_of() are the same task, no matter what
    dates or ages have been stamped on them.
    """
    b = re.sub(r"^\[>\]\s*", "", body)
    b = re.sub(r"\s*\(\d+d\)$", "", b)
    b = re.sub(r"\s*\[[a-z]+::[^\]]*\]", "", b)
    return re.sub(r"\s+", " ", b).strip()


def field(body, name):
    m = re.search(rf"\[{name}:: ([^\]]+)\]", body)
    return m.group(1) if m else None


def restamp(body, today, fallback):
    """Ensure [created::], refresh the (Nd) age. Never stack age stamps."""
    body = re.sub(r"^\[>\]\s*", "", body)          # legacy auto-tasks prefix
    body = re.sub(r"\s*\(\d+d\)$", "", body).rstrip()
    created = field(body, "created")
    if not created:
        created = fallback
        body += f" [created:: {created}]"
    age = (today - datetime.date.fromisoformat(created)).days
    return f"{body} ({age}d)", age


def carry(lines, today, src_date, out, graduated=None, max_age=None):
    """Carry open tasks from one section, restamped. Sub-tasks ride along.

    If max_age is set, a task older than it is diverted to `graduated`
    instead - that is how a stale HOOK becomes a BACKLOG task.
    """
    n = 0
    for line in lines:
        m = TASK_RE.match(line)
        if not m or m.group("st") not in OPEN:
            continue
        if not text_of(m.group("body")):
            continue  # empty template checkbox - nothing to carry
        body, age = restamp(m.group("body"), today, src_date)
        rebuilt = f"{m.group('ind')}- [{m.group('st')}] {body}"
        if max_age is not None and age > max_age and graduated is not None:
            graduated.append(rebuilt)
        else:
            out.append(rebuilt)
        n += 1
    return n


def admit_slated(today, backlog):
    """Move due tasks out of SLATED into BACKLOG. Move, never copy."""
    if not os.path.exists(SLATED):
        return 0, 0
    lines = open(SLATED, encoding="utf-8").read().split("\n")
    kept, admitted = [], 0
    for line in lines:
        m = TASK_RE.match(line)
        if not m or m.group("st") not in OPEN:
            kept.append(line)
            continue
        body = m.group("body")
        when = field(body, "scheduled") or field(body, "due")
        if when and datetime.date.fromisoformat(when) <= today:
            stamped, _ = restamp(body, today, when)
            backlog.append(f"- [{m.group('st')}] {stamped}")
            admitted += 1
        else:
            kept.append(line)  # not due - stays put, untouched
    if admitted:
        open(SLATED, "w", encoding="utf-8").write("\n".join(kept))
    waiting = sum(1 for l in kept if TASK_RE.match(l))
    return admitted, waiting


def dedupe(items):
    """First occurrence of each task wins. Later ones are dropped.

    The file-exists guard is an optimization; this is the guarantee. A task
    must never appear twice in one note regardless of how often we run.
    """
    seen, out = set(), []
    for line in items:
        m = TASK_RE.match(line)
        k = text_of(m.group("body")) if m else line
        if k in seen:
            continue
        seen.add(k)
        out.append(line)
    return out


def main():
    today = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 \
        else logical_today()
    dest = note_path(today.isoformat())

    if os.path.exists(dest):
        print(f"exists, nothing to do: {dest}")
        return 0
    if not os.path.exists(TEMPLATE):
        sys.exit(f"template missing: {TEMPLATE}")

    src = prior_note(today)
    if src is None:
        sys.exit("no prior TODO note found - refusing to invent an empty backlog")

    src_secs = sections(note_path(src))
    hooks, backlog = [], []

    # HOOK -> tomorrow's HOOK, unless it has gone stale -> BACKLOG
    n_hook = carry(src_secs.get("HOOK", []), today, src, hooks,
                   graduated=backlog, max_age=HOOK_MAX_DAYS)
    n_grad = len(backlog)

    # Unfinished TODO falls back to the pile. HABITS never carry.
    n_todo = carry(src_secs.get("TODO", []), today, src, backlog)
    n_back = carry(src_secs.get("BACKLOG", []), today, src, backlog)

    n_admit, n_wait = admit_slated(today, backlog)

    body = open(TEMPLATE, encoding="utf-8").read()
    body = body.replace("{{date:YYYY-MM-DD}}", today.isoformat())

    def fill(text, heading, items):
        if not items:
            return text
        block = "\n".join(items)
        if f"## {heading}" in text:
            return text.replace(f"## {heading}\n", f"## {heading}\n\n{block}\n", 1)
        return text.rstrip("\n") + f"\n\n## {heading}\n\n{block}\n"

    hooks = dedupe(hooks)
    backlog = dedupe(backlog)

    body = fill(body, "HOOK", hooks)
    body = fill(body, "BACKLOG", backlog)
    body = "\n".join(l.rstrip() for l in body.split("\n"))
    body = re.sub(r"\n{3,}", "\n\n", body)
    if not body.endswith("\n"):
        body += "\n"

    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(body)

    carried = n_hook - n_grad
    summary = (f"carried {carried} hook, {n_todo + n_back} backlog; "
               f"{n_grad} hook->backlog; {n_admit} admitted, {n_wait} slated")
    print(f"created: {dest}\n{summary}")

    os.makedirs(CHANGELOG, exist_ok=True)
    log = os.path.join(CHANGELOG, f"{today.isoformat()}-changelogs.md")
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(f"\n## hook | {today.isoformat()} TODO\n\n- {summary}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
