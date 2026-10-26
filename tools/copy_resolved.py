import os
import shutil
import sys


def CopyResolved(source, destination, active, excluded):
    os.makedirs(destination, exist_ok=True)
    for entry in os.scandir(source):
        if any(character in entry.name for character in '<>:"|?*\\'):
            continue
        if entry.name in excluded:
            continue
        resolved = os.path.realpath(entry.path)
        if not os.path.exists(resolved):
            continue
        target = os.path.join(destination, entry.name)
        if os.path.isdir(resolved):
            if resolved in active:
                continue
            CopyResolved(resolved, target, active + [resolved], [])
        else:
            shutil.copy2(resolved, target)


source = os.path.realpath(sys.argv[1])
CopyResolved(source, sys.argv[2], [source], sys.argv[3:])
