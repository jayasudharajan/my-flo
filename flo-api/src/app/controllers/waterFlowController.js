import _ from 'lodash';
import LocationTable from '../models/LocationTable';
import WaterflowService from '../services/waterflow-v1_5/WaterflowService';
import waterflowContainer from '../services/waterflow-v1_5/container';

const location = new LocationTable();

//TODO Make these environment variables.
const daily_water_goal = 60; // gallons


const waterflowService = waterflowContainer.get(WaterflowService);

/**
 * NOTE: Retrieves daily water usage grouped by hour.
 * Returns: ["0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",
 *  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.7",  "0.1",  "0.0",  "0.0",
 *  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0",  "0.0"]
 */
export function retrieveDailyWaterFlow(req, res, next) {
    const { device_id } = req.params;

    waterflowService.retrieveDailyWaterFlowByDeviceId(device_id)
        .then(dailyUsage => {
            res.status(200).send(dailyUsage);
        })
        .catch(err => next(err));
}

/**
 * NOTE: Retrieves total daily water usage.
 */
export function retrieveDailyTotalWaterFlow(req, res, next) {
    const { device_id } = req.params;
    
    waterflowService.retrieveDailyTotalWaterFlowByDeviceId(device_id)
        .then(result => {
            res.status(200).send(result);
        })
        .catch(err => next(err));
}

/**
 * Gets all water usage from the 1st of the month.
 * TODO: Make time calculation timezone aware.
 *       Also see: https://www.pivotaltracker.com/story/show/126953051
 */
export function retrieveMonthlyUsage(req, res, next) {
    const { device_id } = req.params;
    const { prev } = req.query;

    waterflowService.retrieveMonthlyUsageByDeviceId(device_id, prev == 'true')
        .then(results => {
            res.status(200).send(results);
        })
        .catch(err => {
            next(err);
        });
}

/**
 * Daily water consumption goal based on declared occupants for a Location.
 */
export function retrieveDailyGoal(req, res, next) {
    const { account_id, location_id } = req.params;

    location.retrieve({ account_id, location_id })
        .then(result => {
            if (!_.isEmpty(result)) {
                // TODO: we need to either make daily usage configurable or
                // have algorithm in the future based on historical / regional usage.
                let occupants = result.Item.occupants ? result.Item.occupants : 1;
                res.status(200).json({ goal: occupants * daily_water_goal });
            }
            else {
                // If location not found, assume 1 occupant OR return err?
                next({ status: 400, message: "User location not found." });
            }
        })
        .catch(err => next(err));
}

export function retrieveLast24HoursConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast24HoursConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLast30DaysConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast30DaysConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLast12MonthsConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast12MonthsConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLast24HourlyAvgs(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast24HourlyAveragesByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLastWeekConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLastWeekConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLast28DaysConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast28DaysConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLastDayConsumption(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLastDayConsumptionByICDId(icd_id, from && parseInt(from))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveTransmittingDevices(req, res, next) {
    const { query: { start, end } } = req;

    return waterflowService.retrieveTransmittingDevices(parseInt(start), parseInt(end))
        .then(results => {
            res.json(results);
        })
        .catch(next);
}

export function retrieveLastDayMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLastDayMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveLastWeekMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLastWeekMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveThisWeekMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveThisWeekMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveLast28DaysMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast28DaysMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveLast24HoursTransmissionRateHourlyByDeviceId(req, res, next) {
    const { params: { device_id }, query: { from } } = req;

    return waterflowService.retrieveLast24HoursTransmissionRateHourlyByDeviceId(device_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveThisWeekMeasurementsByGroupId(req, res, next) {
    const { params: { group_id }, query: { from, tz } } = req;

    return waterflowService.retrieveThisWeekHourlyMeasurementsByGroupId(group_id, from && parseInt(from), tz)
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveLast12MonthsMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast12MonthsMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}

export function retrieveLast24HoursMeasurements(req, res, next) {
    const { params: { icd_id }, query: { from } } = req;

    return waterflowService.retrieveLast24HoursMeasurementsByICDId(icd_id, from && parseInt(from))
        .then(results => res.json(results))
        .catch(next);
}
