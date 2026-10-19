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
        key:value
    
    There's a special key called :done: that you can assign any value.
    When you run tm, it will properly highlight tasks without this key.
    This way you can easily identify all your to-do tasks and find
    new ones to work on.
"""

import os


def list_tasks():
    file_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = file_dir + "/tm.pro"
    f = open(file_path)
    tasks = []
    cur = ""
    for line in f.readlines():
        if len(line) > 1 and not cur:
            cur, name = line.split(":")
            tasks.append({"id": cur, "name": name.strip(), "description": []})
            continue

        if len(line) > 1:
            if line.startswith(":"):
                _, key, value = line.split(":")
                tasks[-1][key] = value
            else:
                tasks[-1]["description"].append(line)
        else:
            cur = ""

    for task in tasks:
        if "done" in task:
            a, b = 90, 90
        else:
            a, b = 32, 92
        print(f"    \033[{a}m[" + task["id"] + "]\033[0m" + ": ",  end="")
        print(f"\033[{b}m" + task["name"] + "\033[0m")

        for line in task["description"]:
            print("    ", line, end="")

        for key in task.keys():
            if key not in ["id", "name", "description", "done"]:
                if "done" not in task:
                    print("    \033[36m" + key + "\033[0m" + ":",  end="")
                    print("\033[96m" + task[key] + "\033[0m", end="")

        print("\n")
 
    return tasks


def is_task_done(_id, tasks):
    for task in tasks:
        if task["id"] == _id:
            return "done" in task


def build_graph(tasks):
    graph = { task["id"]: [] for task in tasks }
    for task in tasks:
        _id = task["id"]
        dependencies = task["depends_on"].strip().split(",") if "depends_on" in task else []
        for dependency in dependencies:
            graph[dependency].append(_id)
    return graph


def build_plan(tasks, graph):
    nodes = graph.keys()

    in_degrees = {node: 0 for node in nodes}
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

    print("    \033[33mSuggested plan:\033[0m")
    i = 0
    for item in plan:
        if not is_task_done(item, tasks):
            i += 1
            print(f"      {i}.", item)
    return plan


tasks = list_tasks()
graph = build_graph(tasks)
plan = build_plan(tasks, graph)