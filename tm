#!/usr/bin/env python3

"""
    tm - task manager

    author: Ronald Kaiser
    date: Oct 18, 2026

    This is a piece of code that prints your .pro file with highlights.
    The idea is to write down the tasks of a project
    in a .pro file.

    The tasks should start with the following format:
        task1: short description
        Multiline description
    
    After the description you can put some key value pairs, e.g.:
        task1: short description
        Multiline description
        :key:value
        :key2:value2
    
    There's a special key called :done: that you can assign any value.
    When you run tm, it will properly highlight tasks without this key.
    This way you can easily identify all your to-do tasks and find
    new ones to work on.
"""

import argparse
import os


def print_task_name(_id, name, done):
    if done:
        a, b = 90, 90
    else:
        a, b = 32, 92
    print(f"\033[{a}m --> [" + _id + "]\033[0m" + ": ",  end="")
    print(f"\033[{b}m" + name + "\033[0m")


def print_task_description(description):
    for line in description:
        print("    ", line, end="")


def print_task_key_values(task):
    for key in task.keys():
        print("     \033[36m" + key + "\033[0m" + ":",  end="")
        print("\033[96m" + task[key] + "\033[0m", end="")


def print_tasks_header_footer(func):
    def wrapper(*args, **kwargs):
        print("tasks".center(50, '.'))
        result = func(*args, **kwargs)
        return result
    return wrapper


def parse_file():
    file_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = file_dir + "/tm.pro"
    f = open(file_path)
    tasks = {}
    cur = ""
    for line in f.readlines():
        if len(line) > 1 and not cur:
            cur, name = line.split(":")
            if cur in tasks:
                raise ValueError(f"task {cur} duplicated")
            tasks[cur] = { "name": name.strip(), "description": [] }
            continue

        if len(line) > 1:
            if line.startswith(":"):
                _, key, value = line.split(":")
                tasks[cur][key] = value
            else:
                tasks[cur]["description"].append(line)
        else:
            cur = ""
    return tasks


def print_stats(tasks):
    print()
    to_do = sum(1 for task in tasks if "done" in tasks[task])
    total = len(tasks)
    print(f"\033[36m --> Done: {to_do} / {total}\033[0m")


@print_tasks_header_footer
def print_tasks(tasks, ignore_done=True):
    print()
    for i, task in enumerate(tasks):
        if not ignore_done and "done" in tasks[task]:
            continue # do not show done tasks 

        print_task_name(task, tasks[task]["name"], done="done" in tasks[task])
        print_task_description(tasks[task]["description"])
        print_task_key_values(
            {
                key:value
                for key, value in tasks[task].items()
                if key not in ["id", "name", "description", "done"]
            }
        )
        print()

    print_stats(tasks)
 
    return tasks


def is_task_done(_id, tasks):
    return "done" in tasks[_id]


def build_graph(tasks):
    graph = { task: [] for task in tasks }
    for task in tasks:
        dependencies = tasks[task]["depends_on"].strip().split(",") if "depends_on" in tasks[task] else []
        for dependency in dependencies:
            graph[dependency].append(task)
    return graph


def topological_sort(graph):
    in_degrees = {node:0 for node in graph} 

    to_process = set()
    for node in graph:
        for u in graph[node]:
            in_degrees[u] += 1

    for node in in_degrees:
        if in_degrees[node] == 0:
            to_process.add(node)

    plan = []

    while to_process:
        node = to_process.pop()
        plan.append(node)
        for u in graph[node]:
            in_degrees[u] -= 1
            if in_degrees[u] == 0:
                to_process.add(u)

    return plan


def build_plan(tasks, graph):
    plan = topological_sort(graph)
    print("plan".center(50, "."))
    i = 0
    for item in plan:
        if not is_task_done(item, tasks):
            i += 1
            print(f"      {i}.", item)

    if i == 0:
        print("All done! Congratz! 🎉 ")
    print("".center(50, "."))
    return plan


def search_tasks(word):
    tasks = parse_file()
    to_print = {}
    for task in tasks:
        for key, value in tasks[task].items():
            if word in key:
                to_print[task] = tasks[task]
                continue
            if isinstance(value, list):
                for item in value:
                    if word in item:
                        to_print[task] = tasks[task]
                        break
            else:
                if word in value:
                    to_print[task] = tasks[task]
    print_tasks(to_print, ignore_done=True)


print("""\033[35m
░▀█▀░█▄█
░░█░░█░█
░░▀░░▀░▀ v0.1
\033[0m""")

parser = argparse.ArgumentParser()
parser.add_argument("-a", "--all", action="store_true", help="print all tasks")
parser.add_argument("-s", "--search", type=str, default="", help="search for word")
args = vars(parser.parse_args())
if args["search"]:
    search_tasks(args["search"])
else:
    all = args["all"]
    tasks = parse_file()
    tasks = print_tasks(tasks, ignore_done=all)
    graph = build_graph(tasks)
    plan = build_plan(tasks, graph)
