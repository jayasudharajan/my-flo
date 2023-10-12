import { countries, USAState, australiaState, germanyState, ukState } from '../../config/constants';

/**
 * Retrieve one CountryStateProvince.
 */
export function retrieveStatesProvinces(req, res, next) {
  const { country } = req.params;

  switch (country.toUpperCase()) {
    case countries.USA: 
      res.json(USAState);
      break;
    case countries.Australia:
      res.json(australiaState);
      break;
    case countries.Germany:
      res.json(germanyState);
    case countries.UK:
      res.json(ukState);
    default:
      next({ status: 404, message: "Country not found." });
      break;
  }
}

export function retrieveCountries(req, res, next) {
  try {
    const countryArray = Object.keys(countries)
      .map(key => countries[key].toUpperCase());

    res.json(countryArray);
  } catch (err) {
    next(err);
  }
}