/**/

#include <unistd.h>
#include <time.h>

#if (_POSIX_TIMERS > 0) && defined(_POSIX_MONOTONIC_CLOCK)
#define OLDEN_TIME(x) clock_gettime(CLOCK_MONOTONIC_RAW, &x)
#define OLDEN_DURATION_MS(start, stop)                                         \
  ((double)stop.tv_sec - start.tv_sec) * 1000 +                                \
      (double)(stop.tv_nsec - start.tv_nsec) / 1000000
#else
#define OLDEN_TIME(x)                                                          \
  do {                                                                         \
  } while (0)
#define OLDEN_DURATION_MS(start, stop) 0
#endif
