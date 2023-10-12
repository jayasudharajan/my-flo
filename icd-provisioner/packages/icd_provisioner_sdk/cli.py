import enum


# Imported from os.EX_* in the STL
class ExitStatus(enum.IntEnum):
    EX_CANTCREAT: int = 73
    EX_CONFIG: int = 78
    EX_DATAERR: int = 65
    EX_IOERR: int = 74
    EX_NOHOST: int = 68
    EX_NOINPUT: int = 66
    EX_NOPERM: int = 77
    EX_NOTFOUND: int = 79
    EX_NOUSER: int = 67
    EX_OK: int = 0
    EX_OSERR: int = 71
    EX_OSFILE: int = 72
    EX_PROTOCOL: int = 76
    EX_SOFTWARE: int = 70
    EX_TEMPFAIL: int = 75
    EX_UNAVAILABLE: int = 69
    EX_USAGE: int = 64
