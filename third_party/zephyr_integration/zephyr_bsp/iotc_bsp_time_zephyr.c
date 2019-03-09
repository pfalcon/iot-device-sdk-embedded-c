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
#include <zephyr.h>

void iotc_bsp_time_init() { /* empty */
}

iotc_time_t iotc_bsp_time_getcurrenttime_seconds() {
  return (k_uptime_get() + (MSEC_PER_SEC/2)) / MSEC_PER_SEC;
}

iotc_time_t iotc_bsp_time_getcurrenttime_milliseconds() {
  return k_uptime_get();
}
