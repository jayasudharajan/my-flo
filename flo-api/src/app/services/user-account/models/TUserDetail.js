import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import unitSystems from '../../locale/models/unitSystems';
import _ from 'lodash';

const TPrefix = t.enums.of([
	'Mr.',
	'Mrs.',
	'Dr.',
	'Miss',
	'Ms.'
]);

const TSuffix = t.enums.of([
	'Jr.',
	'Sr.',
	'II',
	'III',
	'IV',
	'V'
]);

const TUserDetail = t.struct({
	user_id: tcustom.UUIDv4,
	firstname: t.maybe(t.String),
	middlename: t.maybe(t.String),
	lastname: t.maybe(t.String),
	phone_mobile: t.maybe(t.String),
	prefixname: t.maybe(TPrefix),
	suffixname: t.maybe(TSuffix),
	unit_system: t.maybe(t.enums.of(_.map(unitSystems, 'id'))),
	locale: t.maybe(t.String)
});

TUserDetail.create = data => TUserDetail(data);

export default TUserDetail;