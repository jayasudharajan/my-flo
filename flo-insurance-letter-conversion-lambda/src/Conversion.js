const fs = require('fs');
const path = require('path');
const pdf = require('html-pdf');
const moment = require('moment-timezone');
const DynamoMicroService = require('./DynamoMicroService');

const S3MicroService = require('./S3MicroService');
const templateKeywords = {
    todays_date: '{{todays_date}}',
    first_name: '{{first_name}}',
    last_name: '{{last_name}}',
    street_address_1: '{{street_address_1}}',
    street_address_2: '{{street_address_2}}',
    city: '{{city}}',
    state: '{{state}}',
    postal_code: '{{postal_code}}',
    expiration_date: '{{expiration_date}}',
    letter_body: '{{letter_body}}'
};

const fileName = 'InsuranceLetter.pdf';
const shutoffDescription = "has purchased and registered a Moen Flo Smart Water Monitor and Shutoff. Our product literature provided with the device and our website states the device is intended to be installed on the main water supply line to the home and, when installed and maintained properly, will reduce the risk of a critical water event in the home.";
const detectorDescription = "currently has a Flo by Moen Smart Water Detector. This device senses water, temperature and humidity and is being monitored 24 hours a day, 7 days a week. When water is detected, the customer is notified of a potential leak in the house through their Flo by Moen mobile application. Notifications are also sent using audible alarms in the house and a phone call to the customer.";

class Conversion {
    constructor() {
    }

    generateLetter(info, test) {
        const html = this._replacePlaceHolders(info, fs.readFileSync(path.resolve(__dirname, './moen.htm'), 'utf8'));
        if (test) {
            return this.writePdfLocally(html)
        } else {
            return this.getPdfBuffer(html)
                .then(pdfStream => new S3MicroService().uploadPdf(pdfStream, `${info.location_id}-${fileName}`))
                .then(s3Metadata => new DynamoMicroService().writeLogRecord(this._getS3UploadMetaData(s3Metadata, info)))

        }
    }

    getPdfBuffer(html) {
        return new Promise((resolve, reject) => {
            pdf.create(html, this._getPdfConfig('pdf')).toBuffer((err, pdfs) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(pdfs);
                }
            });
        })
    }

    writePdfLocally(html) {
        return new Promise((resolve, reject) => {
            pdf.create(html, this._getPdfConfig('pdf')).toFile('test.pdf', (err, pdfs) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(pdfs);
                }
            });
        })
    }

    _getS3UploadMetaData(metadata, info) {
        return {
            location_id: info.location_id,
            generated_at: moment().toISOString(),
            created_at: info.created_at,
            s3_key: metadata.Key,
            s3_bucket: metadata.Bucket,
            s3_location: metadata.Location
        };
    }

    _replacePlaceHolders(userInfo, htmlLetter) {
        const today = moment().tz(userInfo.time_zone).format('MMMM DD, YYYY');
        const expirationDate = moment(userInfo.expiration_date).tz(userInfo.time_zone).format('MMMM DD, YYYY');
        const placeHolders = this._getPlaceHolders(today, expirationDate, userInfo);
        const hasDetector = (userInfo.devices || []).find(d => d.device_type === 'puck_oem') !== undefined;
        const hasShutoff = (userInfo.devices || []).find(d => d.device_type === 'flo_device_v2') !== undefined;
        const letterBody = hasDetector && !hasShutoff ? detectorDescription : shutoffDescription;

        return htmlLetter
            .replace(templateKeywords.postal_code, placeHolders.postal_code)
            .replace(templateKeywords.todays_date, placeHolders.todaysDate)
            .replace(templateKeywords.first_name, placeHolders.firstName)
            .replace(templateKeywords.last_name, placeHolders.lastName)
            .replace(templateKeywords.street_address_1, placeHolders.streetAddress1)
            .replace(templateKeywords.street_address_2, placeHolders.streetAddress2)
            .replace(templateKeywords.city, placeHolders.city)
            .replace(templateKeywords.state, placeHolders.state)
            .replace(templateKeywords.postal_code, placeHolders.postal_code)
            .replace(templateKeywords.expiration_date, placeHolders.expirirationDate)
            .replace(templateKeywords.letter_body, letterBody);
    }

    _getPlaceHolders(today, expirationDate, userInfo) {
        return {
            todaysDate: today,
            firstName: userInfo.first_name,
            lastName: userInfo.last_name,
            streetAddress1: userInfo.street_address_1,
            streetAddress2: userInfo.street_address_2,
            city: userInfo.city,
            state: userInfo.state,
            postal_code: userInfo.zip,
            expirirationDate: expirationDate
        };
    }

    _getPdfConfig(fileType) {
        return {
            format: 'Letter',
            orientation: 'portrait',
            border: {
                top: '0.5in',
                right: '1in',
                bottom: '0.5in',
                left: '1in'
            },
            type: fileType,
            quality: '100',
        };
    }

}

module.exports = Conversion;



