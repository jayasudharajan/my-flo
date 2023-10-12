
class KafkaProducerMock {

  constructor() {
    this.data = [];
  }

  clear() {
    this.data = [];
  }

  getSentMessages(topic) {
    return this.data.filter(function(item) {
      return !topic || item.topic == topic;
    }).map(function (item) {
      return JSON.parse(item.message);
    });
  }

  send(topic, messages, sendPlaintext) {
    (Array.isArray(messages) ? messages : [messages]).forEach(message => {
      this.data.push({
        topic: topic,
        message: message
      })
    });

    return Promise.resolve(messages);
  }

  encrypt(message) {
    return Promise.resolve(message);
  }
}

module.exports = KafkaProducerMock;