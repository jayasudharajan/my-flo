import _ from 'lodash';
import { directiveDataMap } from './models/directiveData';
import directivesServiceWrapper from './directivesServiceWrapper';

function createControllerFn(sendDirective) {
    return (req, res, next) => {
        const { params: { icd_id, user_id }, body } = req;

        sendDirective(icd_id, user_id, req.app_used, body)
            .then(() => res.status(202).send())
            .catch(next);
    };
}

const controller = _.mapValues(
    directiveDataMap, 
    (value, directiveName) => createControllerFn(directivesServiceWrapper[directiveName])
);


controller.retrieveDirectiveLogByDirectiveId = function ({ params: { directive_id } }, res, next) {
  return directivesServiceWrapper.retrieveDirectiveLogByDirectiveId(directive_id)
    .then(result => res.json(result))
    .catch(next);
};

export default controller;