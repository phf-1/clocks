from clocks.maybe import Maybe


class Seq:
    """[[id:9ed13610-3d9b-4ee1-b320-7d2b2ffd7947][Seq]]

    This module extracts augments sequence behaviors
    """

    @staticmethod
    def get(seq, idx):
        """Sequence(X) ℕ → Maybe(X)"""
        if idx >= 0 and idx < len(seq):
            return Maybe.just(seq[idx])
        return Maybe.nothing()
