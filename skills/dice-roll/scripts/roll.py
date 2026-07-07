#!/usr/bin/env python3
"""dice-roll: roll a fair six-sided die and print the result as JSON."""
import json
import random

SIDES = 6


def roll(sides: int = SIDES) -> int:
    return random.randint(1, sides)


if __name__ == "__main__":
    print(json.dumps({"sides": SIDES, "result": roll()}))
