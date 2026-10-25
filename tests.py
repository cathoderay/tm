import unittest

from tm import is_task_done


class TaskManagerTests(unittest.TestCase):
    def test_task_done(self):
        task_id = "id"
        tasks = {task_id: {"done": ""}}
        assert is_task_done(task_id, tasks) == True

    def test_task_not_done(self):
        task_id = "id"
        tasks = {task_id: {"name": "test"}}
        assert is_task_done(task_id, tasks) == False


if __name__ == "__main__":
    unittest.main()