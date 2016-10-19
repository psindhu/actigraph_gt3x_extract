import numpy as np
a = np.array([[2], [7], [23]], dtype=np.uint8)
b = np.unpackbits(a, axis=None)
print b[:12]
print b[12:]

def read12(x):
    SIZE = 12
    bits = np.unpackbits(x, axis=None)
    assert len(bits) % SIZE == 0

    bits_12 = bits.reshape((-1, 12))

    n_numbers = bits_12.shape[0]

    bits_16 = np.concatenate([ np.zeros((n_numbers, 4), dtype=np.uint8), bits_12], axis=1)

    output = []
    for row in bits_16:
        row = "".join([str(c) for c in row])
        val16 = int(row, 2)
        output += [val16]
    return output

print read12(a)
