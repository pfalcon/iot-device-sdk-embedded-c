/* Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <iotc_bsp_time.h>
#include <stdio.h>
#include <zephyr.h>
#include <net/sntp.h>
#include <time.h>

u64_t time_base;

void iotc_bsp_time_init() {
  struct sntp_time ts;
  int res = sntp_simple("time.nist.gov", 3000, &ts);

  if (res < 0) {
    printf("Cannot acquire current time\n");
    exit(1);
  }

  time_base = ts.seconds - k_uptime_get() / MSEC_PER_SEC;

  printf("Acquired current time: %u\n", (unsigned)time_base);

  struct timespec tspec;
  tspec.tv_sec = ts.seconds;
  tspec.tv_nsec = ((u64_t)ts.fraction * (1000 * 1000 * 1000)) >> 32;
  res = clock_settime(CLOCK_REALTIME, &tspec);
  printf("clock_settime: %d, errno: %d\n", res, errno);
}

iotc_time_t iotc_bsp_time_getcurrenttime_seconds() {
  return (k_uptime_get() + (MSEC_PER_SEC/2)) / MSEC_PER_SEC + time_base;
}

iotc_time_t iotc_bsp_time_getcurrenttime_milliseconds() {
  return k_uptime_get();
}
