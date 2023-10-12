import DirectiveLogTable from '../models/DirectiveLogTable';
var config = require('../../config/config');

var directiveLog = new DirectiveLogTable();

export function track(req, res, next) {
    let { icd_id, directive, state } = req.body;

    directiveLog.create({
        icd_id,
        state,
        status: 'sent',
        directive_type: directive.directive,
        directive: JSON.stringify(directive),
        created_at: new Date().toISOString()
    })
    .then(() => {
        res.status(200).send();
    })
    .catch(err => next(err));
}
