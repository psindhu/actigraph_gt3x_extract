import struct
import numpy as np
import logging
import json
import os
import sys
from glob import glob, iglob
logging.basicConfig(filename='unpack_bits.log', level=logging.DEBUG, filemode='a')
logger = logging.getLogger(__name__)


def read12(x):
    SIZE = 12
    bits = np.unpackbits(x, axis=None)
    assert len(bits) % SIZE == 0

    bits_12 = bits.reshape((-1, 12))
    n_numbers = bits_12.shape[0]
    bits_16 = np.concatenate([np.zeros((n_numbers, 4), dtype=np.uint8),
                              bits_12], axis=1)
    output = []
    for row in bits_16:
        row = "".join([str(c) for c in row])
        val16 = int(row, 2)
        output += [val16]
    return output


def unpack(file_dir):
    file_path = os.path.join(file_dir, 'log.bin')
    if not os.path.exists(file_path):
        raise ValueError('No file: %s' % file_path)

    acc = dict()
    lux = dict()
    battery = dict()
    with open(file_path, mode='rb') as file:
        try:
            while True:
                sep, payload_type, timestamp, size = struct.unpack("<cbLH", file.read(8))

                if payload_type == 6:
                    metadata, = struct.unpack("%ds" % size, file.read(size))
                    metadata = json.loads(metadata.decode('utf-8'))

                elif payload_type == 2:
                    battery[timestamp], = struct.unpack("<H", file.read(size))

                elif payload_type == 5:
                    lux[timestamp], = struct.unpack("<H", file.read(size))

                elif payload_type == 0:
                    # acc[timestamp] = read12(np.array(struct.unpack('%dB' % size, file.read(size)), dtype=np.uint8))
                    # logger.info('Writing %d samples to acc' % len(acc[timestamp]))
                    acc[timestamp] = size
                    file.seek(size, 1)
                else:
                    logger.debug('Payload: %d, dir: %s' % (payload_type, file_dir))
                    break
                checksum, = struct.unpack("B", file.read(1))
        except struct.error:
            pass

    dir_name = os.path.dirname(file_dir)
    json.dump(acc, open(os.path.join(dir_name, 'acc.json'), 'w'))
    json.dump(battery, open(os.path.join(dir_name, 'battery.json'), 'w'))
    json.dump(lux, open(os.path.join(dir_name, 'lux.json'), 'w'))
    json.dump(metadata, open(os.path.join(dir_name, 'metadata.json'), 'w'))


if __name__ == '__main__':
    base_dir = sys.argv[1]

    for filename in glob(base_dir+'**/*.gt3x', recursive=True):
        unpack(filename.split('.')[0])
