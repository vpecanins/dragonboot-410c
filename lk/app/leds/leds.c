/*
 * Copyright (c) 2018 Victor Pecanins
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#include <app.h>
#include <debug.h>
#include <compiler.h>
#include <platform/gpio.h>
#include <pm8x41.h>

volatile unsigned int led_period = 1000;

static void leds_init(const struct app_descriptor *app)
{
	gpio_tlmm_config(21, 0, GPIO_OUTPUT, GPIO_NO_PULL, GPIO_16MA, 1);
	gpio_tlmm_config(120, 0, GPIO_OUTPUT, GPIO_NO_PULL, GPIO_16MA, 1);
	
	struct pm8x41_gpio pm_cfg = {
		.direction = PM_GPIO_DIR_OUT,
		.output_buffer = PM_GPIO_OUT_CMOS,
		.output_value = 1,
		.pull = PM_GPIO_PULL_UP_30,
		.vin_sel = 0,
		.out_strength = PM_GPIO_OUT_DRIVE_HIGH,
		.function = PM_GPIO_FUNC_LOW,
		.inv_int_pol = 0,
		.disable_pin = 0
	};
	
	pm8x41_gpio_config(1, &pm_cfg);
	pm8x41_gpio_config(2, &pm_cfg);
	pm8x41_gpio_set(1, 0);
	pm8x41_gpio_set(2, 0);
	
	while (1) {
		gpio_set_dir(21, 2);
		gpio_set_dir(120, 0);

		mdelay(led_period);

		gpio_set_dir(21, 0);
		gpio_set_dir(120, 2);
		
		mdelay(led_period);
		
		gpio_set_dir(120, 0);
		pm8x41_gpio_set(1, 1);
		
		mdelay(led_period);
		
		pm8x41_gpio_set(1, 0);
		pm8x41_gpio_set(2, 1);
		
		mdelay(led_period);
		
		pm8x41_gpio_set(2, 0);
		pm8x41_gpio_set(1, 1);
		
		mdelay(led_period);
		
		pm8x41_gpio_set(1, 0);
		gpio_set_dir(120, 2);
		
		mdelay(led_period);
	}
}

APP_START(leds)
	.init = leds_init,
	.flags = 0,
APP_END

