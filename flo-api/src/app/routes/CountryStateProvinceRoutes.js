import express from 'express';
import { checkPermissions } from '../middleware/acl';

let CountryStateProvinceController = require('../controllers/CountryStateProvinceController');

export default (app) => {

  let router = express.Router();
  let requiresPermission = checkPermissions('CountryStateProvince');

  // Get, update, patch, delete.
  router.route('/:country')
    .get(
      CountryStateProvinceController.retrieveStatesProvinces
    );

  router.route('/')
  	.get(
  	  CountryStateProvinceController.retrieveCountries
  	);

  app.use('/api/v1/countrystateprovinces', router);

}