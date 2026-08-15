"""B-BervigES.kernel — constructive Erdős–Straus solver."""

from .solve import SolveResult, Solver
from .witness import Witness, verify_witness

__all__ = ["Solver", "SolveResult", "Witness", "verify_witness"]
__version__ = "0.1.0"
__kernel_name__ = "B-BervigES.kernel"
