import * as t from 'io-ts';
import _ from 'lodash';

export const CallbackParameterCodec = t.type({
  incidentId: t.string,
  userId: t.string
});

export type CallbackParameters = t.TypeOf<typeof CallbackParameterCodec>;

export class CallbackData {
  constructor(
    public pathParameters: CallbackParameters,
    public body: any,
    private readonly headers: { [name: string]: string },
  ) {
    this.headers = _.mapKeys(headers, (_, k) => k.toLowerCase())
  }

  public getHeader(name: string): string {
    return this.headers[name.toLowerCase()];
  }
}
