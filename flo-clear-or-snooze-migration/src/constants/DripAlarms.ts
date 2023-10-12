const DripAlarms = {
  DRIP_SMALL: 28,
  DRIP_SMALLER: 29,
  DRIP_EVEN_SMALLER: 30,
  DRIP_SMALLEST: 31
};

function isDripAlarm(alarmId: number) {
  return alarmId == DripAlarms.DRIP_SMALL ||
    alarmId == DripAlarms.DRIP_SMALLER ||
    alarmId == DripAlarms.DRIP_EVEN_SMALLER ||
    alarmId == DripAlarms.DRIP_SMALLEST;
}

export default {
  ...DripAlarms,
  isDripAlarm
};
