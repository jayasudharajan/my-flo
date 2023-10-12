import qr from 'qr-image';

export default {
	base64(data) {
	    const qrCode = qr.imageSync(data, { type: 'svg' });
	    return new Buffer(qrCode).toString('base64');
	},
	stream(data) {
    	const qrCode = qr.image(data, { type: 'svg' });
    	return qrCode;
	},
	svg(data) {
		const qrCode = qr.imageSync(data, { type: 'svg' });
		return qrCode;
	}
};