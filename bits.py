"""helper module for exploring bit-packed data words"""

from dataclasses import dataclass

@dataclass
class BitFieldSpec:
    """name a bit field and say how many bits it corresponds to

    where this bit field is in the word is determined by its position in the list of fields"""

    name: str
    nbits: int


@dataclass
class Word:
    """associate a word with a field spec"""
    word: int
    fields: List[BitFieldSpec]
    
    def __post_init__(self):
        cw = self.word
        for f in reversed(self.fields):
            f.val = (cw & ((1 << f.nbits) - 1))
            cw >>= f.nbits


def print_by_field(word, fields):
    cw = word
    field_vals = []
    for name, nbits in reversed(fields):
        field_vals.append(cw & ((1 << nbits) - 1))
        cw >>= nbits
    

    for (name, nbits), val in zip(fields, reversed(field_vals)):
        print(name, nbits, f'{val:0{nbits}}')

