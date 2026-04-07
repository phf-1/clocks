# [[id:9ed13610-3d9b-4ee1-b320-7d2b2ffd7947][Seq]]
#
# This module extracts augments sequence behaviors

from maybe import Maybe

class Seq:
    """
    get : Sequence(X) → Maybe(X)
    """

    @staticmethod
    def get(seq, idx):
        if 0 <= idx and idx < len(seq):
            return Maybe.just(seq[idx])
        else:
            return Maybe.nothing()
