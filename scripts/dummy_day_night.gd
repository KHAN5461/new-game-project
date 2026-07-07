class_name DayAndNightCycle
extends Node

enum DAY_STATE {
    MORNING,
    NOON,
    EVENING,
    NIGHT
}

signal changeDayTime(state: DAY_STATE)
