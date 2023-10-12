import logging
from typing import Callable, List


def make_optional_bool_listener_to_listeners_tunnel(
        listeners: List[Callable], contra_listeners: List[Callable]) -> Callable[..., type(None)]:
    def listener(*args):
        input_: bool = True
        if args and type(args[0]) == bool:
            input_ = args[0]
        func: Callable
        for func in listeners:
            try:
                func(input_)
            except Exception as e:
                logging.getLogger(__package__).info(e)
        for func in contra_listeners:
            try:
                func(not input_)
            except Exception as e:
                logging.getLogger(__package__).info(e)
    return listener
