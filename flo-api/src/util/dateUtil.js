let self = module.exports = {
    /**
     * Date in UTC (as ISO8601 millisecond-precision string, shifted to UTC)
     */
    iso8601Date: function() {
      return new Date().toISOString();
    },

    /**
     * AWS DynamoDB Date type requires a string value as ISO8601 millisecond-precision string, shifted to UTC.
     * See: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.DataTypes.html
     * 2016-06-16T19:24:17.949Z
     */
    dynamoDbDate: function() {
      return self.iso8601Date();
    }
};
