import express from 'express';
import OnboardingController from './OnboardingController';
import AuthMiddleware from '../utils/AuthMiddleware';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from  '../../../util/DIFactory';
import requestTypes from './models/requestTypes';
import ACLMiddleware from '../utils/ACLMiddleware';
import ICDService from '../icd-v1_5/ICDService';
import ICDLocationProvider from '../utils/ICDLocationProvider';

class OnboardingRouter {

	constructor(controller, authMiddleware, aclMiddleware, icdService) {
		const router = express.Router();
		this.router = router;
    this.icdLocationProvider = new ICDLocationProvider(icdService);

    router.route('/event/device/paired')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.doOnDevicePaired),
        aclMiddleware.requiresPermissions([
          {
            resource: 'Onboarding',
            permission: 'triggerEvent'
          }
        ]),
        controller.doOnDevicePaired.bind(controller)
      );

		router.route('/event/device/forced-sleep-disabled')
			.post(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.doOnSystemModeUnlocked),
        aclMiddleware.requiresPermissions([
          {
            resource: 'Onboarding',
            permission: 'triggerEvent'
          }
        ]),
				controller.doOnSystemModeUnlocked.bind(controller)
			);

    router.route('/event/device/installed')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.doOnDeviceInstalled),
        aclMiddleware.requiresPermissions([
          {
            resource: 'Onboarding',
            permission: 'triggerEvent'
          }
        ]),
        controller.doOnDeviceInstalled.bind(controller)
      );


    router.route('/event/device')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.doOnDeviceEvent),
        aclMiddleware.requiresPermissions([
          {
            resource: 'Onboarding',
            permission: 'triggerEvent'
          },
          {
            resource: 'Location',
            permission: 'triggerOnboardingEvent',
            get: (...args) => this.icdLocationProvider.getLocationIdByDeviceIdBody(...args)
          }
        ]),
        controller.doOnDeviceEvent.bind(controller)
      );

    router.route('/icd/:icd_id/current')
      .get(
        authMiddleware.requiresAuth({ addLocationId: true }),
        reqValidate(requestTypes.retrieveCurrentState),
        aclMiddleware.requiresPermissions([
          {
            resource: 'Location',
            permission: 'retrieveCurrentICDOnboardingState',
            get: ({ params: { icd_id } }) => icdService.retrieve(icd_id).then(({ Item = {} }) => Item.location_id)
          }
        ]),
        controller.retrieveCurrentState.bind(controller)
      );
	}

	routes() {
		return this.router;
	}
}

export default new DIFactory(OnboardingRouter, [ OnboardingController, AuthMiddleware, ACLMiddleware, ICDService ]);




