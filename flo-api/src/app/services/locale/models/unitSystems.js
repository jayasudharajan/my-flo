import TTemperatureUnit from './TTemperatureUnit';
import TVolumeUnit from './TVolumeUnit';
import TPressureUnit from './TPressureUnit';

export default [
  {
    id: 'imperial_us',
    name: 'Imperial',
    units: {
      pressure: mapUnit(TPressureUnit, 'PSI'),
      volume: mapUnit(TVolumeUnit, 'Gallon'),
      temperature: mapUnit(TTemperatureUnit, 'Fahrenheit')
    }
  },
  {
    id: 'metric_kpa',
    name: 'Metric',
    units: {
      pressure: mapUnit(TPressureUnit, 'kPa'),
      volume: mapUnit(TVolumeUnit, 'Liter'),
      temperature: mapUnit(TTemperatureUnit, 'Celsius')
    }
  }
];

function mapUnit(unitType, unitName) {
  return {
    name: unitName,
    abbrev: unitType[unitName]
  };
}