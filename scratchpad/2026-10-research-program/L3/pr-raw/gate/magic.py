def magic16(K):
    """Smallest s (and M = ceil(2^s/K)) with (y*M) >> s == y // K for all y < 2^16."""
    for s in range(16, 48):
        M = -(-(1 << s) // K)
        if all(((y * M) >> s) == y // K for y in range(0, 1 << 16, 1)):
            return M, s
