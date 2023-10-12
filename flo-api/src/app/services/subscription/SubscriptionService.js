import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import CrudService from '../utils/CrudService';
import UserAccountService from '../user-account/UserAccountService';
import AccountService from '../account-v1_5/AccountService';
import AuthorizationService from '../authorization/AuthorizationService';
import AccountSubscriptionTable from './AccountSubscriptionTable';
import SubscriptionPlanTable from './SubscriptionPlanTable';
import ServiceException from '../utils/exceptions/ServiceException';
import StripeClient from 'stripe';
import SubscriptionConfig from './SubscriptionConfig';
import TSubscriptionStatus from './models/TSubscriptionStatus';
import moment from 'moment';
import LocationService from '../location-v1_5/LocationService';

class SubscriptionService extends CrudService {

  constructor(userAccountService, accountService, locationService, authorizationService, accountSubscriptionTable, subscriptionPlanTable, stripeClient, subscriptionConfig) {
    super(accountSubscriptionTable);

    this.userAccountService = userAccountService;
    this.accountService = accountService;
    this.locationService = locationService;
    this.authorizationService = authorizationService;
    this.accountSubscriptionTable = accountSubscriptionTable;
    this.subscriptionPlanTable = subscriptionPlanTable;
    this.stripeClient = stripeClient;
    this.subscriptionConfig = subscriptionConfig;
  }

  _retrieveAccountSubscriptionByUserId(userId) {
    return this.accountService.retrieveByOwnerUserId(userId)
      .then(({ Items: [account] }) => {
        if (!account) {
          return Promise.reject(new ServiceException('User/account does not exist'));
        }

        return this.accountSubscriptionTable.retrieve({ account_id: account.id });
      })
      .then(({ Item }) => Item);    
  }

  _formatPaymentSources(customer) {
    const defaultSource = customer && customer.default_source;
    const creditCards = (
      !customer || !customer.sources ?
        [] :
        customer.sources.data
    )
    .filter(source => {
      return source.last4 && source.exp_month && source.exp_year;
    })
    .map(source => {
      return {
        ..._.pick(source, ['last4', 'exp_month', 'exp_year', 'brand']),
        is_default: source.id === defaultSource
      };
    });

    return {
      items: creditCards
    };
  }

  retrieveCreditCardByUserId(userId) {
    return this._retrieveAccountSubscriptionByUserId(userId)
      .then(subscription => {
        if (!subscription) {
          return null;
        }

        return this.stripeClient.customers.retrieve(subscription.stripe_customer_id);
      })
      .then(customer => {
        return this._formatPaymentSources(customer);
      });
  }

  updateCreditCardByUserId(userId, token) {
    return this._retrieveAccountSubscriptionByUserId(userId)
      .then(accountSubscription => {

        if (!accountSubscription) {
          return new Promise.reject(new ServiceException('No existing subscription.'));
        }

        return Promise.all([
          accountSubscription,
          this.stripeClient.customers.createSource(accountSubscription.stripe_customer_id, { source: token })
        ]);
      })
      .then(([accountSubscription, card]) => {
        return this.stripeClient.customers.update(accountSubscription.stripe_customer_id, {
          default_source: card.id
        });
      })
      .then(customer => this._formatPaymentSources(customer));
  }

  _cancelSubscription(subscriptionId, cancelImmediately) {
    return cancelImmediately ?
      this.stripeClient.subscriptions.del(subscriptionId) :
      this.stripeClient.subscriptions.update(subscriptionId, { cancel_at_period_end: true });
  }

  cancelSubscriptionByAccountId(accountId) {
    return this.accountSubscriptionTable.retrieve(accountId)
      .then(({ Item: accountSubscription }) => {
        if (
          !accountSubscription || 
          !accountSubscription.stripe_customer_id || 
          accountSubscription.status == TSubscriptionStatus.canceled
        ) {
          return [];
        } 

        const { stripe_customer_id } = accountSubscription;

        return this.stripeClient.customers.retrieve(stripe_customer_id)
          .then(customer => {
            const subscriptionCancelPromises = !customer ||
              !customer.subscriptions || 
              !customer.subscriptions.data ? 
                [] : 
                customer.subscriptions.data
                  .map(({ id, status }) => 
                    this._cancelSubscription(id, status == TSubscriptionStatus.trialing)
                      .then(() => id)
                  )

            return Promise.all(subscriptionCancelPromises);
          });
      })
      .then(subscriptions => ({ subscriptions }));
  }

  cancelSubscriptionByUserId(userId, cancellationReason) {
    return this._retrieveAccountIdByUserId(userId)
      .then(accountId => {
        if (accountId) {
          return Promise.all([
            this.cancelSubscriptionByAccountId(accountId),
            cancellationReason && this.accountSubscriptionTable.patch(
              { account_id: accountId }, 
              { cancellation_reason: cancellationReason }
            )
          ])
          .then(([subscriptions]) => subscriptions);
        }

        return { subscriptions: [] };
      });
  }

  retrieveCouponInfo(couponId) {
    return this.stripeClient.coupons.retrieve(couponId);
  }

  retrieveSubscriptionPlan(planId) {
    return (
      planId === 'default' ? 
        this.subscriptionConfig.getDefaultPlanId() :
        Promise.resolve(planId) 
      ) 
      .then(planId => this.subscriptionPlanTable.retrieve(planId))
      .then(({ Item }) => 
          _.isEmpty(Item) ? 
          this.subscriptionConfig.getDefaultPlanId()
            .then(planId => this.retrieveSubscriptionPlan(planId)) :
            Item      
      );
  }

  _retrieveAccountIdByUserId(userId) {
    return this.authorizationService.retrieveUserResources(userId, 'Account')
      .then((accountIds = []) => accountIds[0]);
  }

  retrieveByUserId(userId) {
    return this._retrieveAccountIdByUserId(userId)
      .then(accountId => {

        if (accountId) {
          return this.retrieve(accountId);
        }
      });
  }

  handleStripePayment(data) {
    const { stripe_token, user_id, plan_id, source_id, coupon_id } = data;

    return Promise.all([
      plan_id || this.subscriptionConfig.getDefaultPlanId(),
      source_id || this.subscriptionConfig.getDefaultSourceId()
    ])
    .then(([plan_id, source_id]) => this._handleStripePayment(stripe_token, user_id, plan_id, source_id, coupon_id));
  }

  _createSubscription(customer, planId, couponId, sourceId, allowTrial = true) {
    const trailingOptions = allowTrial ? 
      {
        trial_from_plan: true
      } :
      {
        trial_end: 'now',
        trial_from_plan: false
      };

    return this.locationService.retrieveByAccountId(customer.metadata.account_id)
      .then(({ Items: [location] }) => this.stripeClient.subscriptions.create({ 
        customer: customer.id,
        items: [{ plan: planId }],
        ...trailingOptions,
        coupon: couponId,
        metadata: {
          is_from_flo_user_portal: true,
          source_id: sourceId,
          location_id: location.location_id
        }
      }))
      .then(subscription => 
        this.accountSubscriptionTable.create({
          account_id: customer.metadata.account_id,
          location_id: subscription.metadata.location_id,
          stripe_customer_id: customer.id,
          status: subscription.status,
          current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),           
          source_id: sourceId,
          plan_id: planId,
          stripe_subscription_id: subscription.id
        })
    );
  }

  _handleStripePayment(stripe_token, user_id, plan_id, source_id, coupon_id) {

    return Promise.all([
      this.userAccountService.retrieveUser(user_id),
      this.accountService.retrieveByOwnerUserId(user_id)
    ])
    .then(([ user, { Items: [account] } ]) => {

      if (!user || !account) {
        return Promise.reject(new ServiceException('User/account does not exist')); 
      }

      return stripe_token ?
        this._ensureStripeCustomer(user, account, source_id) :
        this._retrieveStripeCustomerByEmail(user.email);
    })
    .then(customer => {

      if (!customer || (!stripe_token && !customer.default_source)) {
        // No card provided or customer with card on file
        return Promise.reject(new ServiceException('Missing card information.'));
      } else if (this._hasActiveSubscription(customer) && this._willCancelAtPeriodEnd(customer)) {
        const subscription = _.find(customer.subscriptions.data, { status: 'active', cancel_at_period_end: true });

        if (!subscription) {
          return Promise.reject(new ServiceException('No subscription found.'));
        }

        return Promise.all([
          this.stripeClient.subscriptions.update(subscription.id, { cancel_at_period_end: false }),
          stripe_token && this._updateStripeCustomerPaymentSource(customer.id, stripe_token)
        ]);

      } else if (this._hasActiveSubscription(customer)) {

        return Promise.reject(new ServiceException('This user already has an existing subscription'));

      } else if (this._hasPastDueSubscription(customer) || this._hasUnpaidSubscription(customer)) {

        // Past due subscriptions must submit a new CC
        if (!stripe_token) {
          return Promise.reject(new ServiceException('Missing card information.'));
        }

        const subscriptionCancelPromises = customer.subscriptions.data
          .filter(({ status }) => 
            status == TSubscriptionStatus.unpaid || 
            status == TSubscriptionStatus.past_due
          )
          .map(({ id }) => this._cancelSubscription(id, true));

       return Promise.all(subscriptionCancelPromises)
        .then(() => this._updateStripeCustomerPaymentSource(customer.id, stripe_token))
        .then(() => this._createSubscription(customer, plan_id, coupon_id, source_id, false));

      } else {

        return Promise.all([
          this._hasPreviouslyCanceledSubscriptions(customer),
          stripe_token && this._updateStripeCustomerPaymentSource(customer.id, stripe_token)
        ])
        .then(([hasPreviousSubscriptions]) => 
          this._createSubscription(customer, plan_id, coupon_id, source_id, !hasPreviousSubscriptions)
        );

      }
    });
  }

  handleStripeWebhookEvent(event) {
    const { type, data } = event;

    switch (type.toLowerCase()) {
      case 'customer.created':
        return this._handleCustomerCreated(data);
      case 'customer.updated':
        return this._handleCustomerUpdated(data);
      case 'customer.deleted':
        return this._handleCustomerDeleted(data);
      case 'customer.subscription.created':
        return this._handleSubscriptionCreated(data);
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted':
        return this._handleSubscriptionUpdatedOrDeleted(data);
      default:
        return Promise.resolve();
    }
  }

  _retrieveAccountIdByStripeCustomer(customer) {
    return this.accountSubscriptionTable.retrieveByStripeCustomerId(customer.id)
      .then(({ Items: [accountSubscription] }) => {

        if (accountSubscription) {
          return accountSubscription.account_id;
        }

        return (
          customer.metadata.account_id ||
            (
              customer.email ? 
                this.userAccountService.retrieveUserByEmail(customer.email).then(result => result && result.id)
                  .then(userId => userId ? this.accountService.retrieveByOwnerUserId(userId) : { Items: [] })
                  .then(({ Items: [account] }) => account && account.id) :
                null
            )
        );
      });
  }

  _updateFromStripeCustomer(customer, isNewCustomer) {
    const subscription = customer && customer.subscriptions.data[0];
    const source_id = customer && customer.metadata.source_id;

    return this._retrieveAccountIdByStripeCustomer(customer)
      .then(accountId => 
        accountId && 
        this.accountSubscriptionTable.patch(
          { account_id: accountId }, 
          _.pickBy({ 
            stripe_customer_id: customer.id,
            source_id,
            created_at: isNewCustomer ? new Date().toISOString() : undefined
          }, value => !_.isUndefined(value))
      ));  
  }

  _handleCustomerCreated(data) {
    if (!data.object.metadata.is_from_flo_user_portal) {
      return this._updateFromStripeCustomer(data.object, true);
    } else {
      return Promise.resolve();
    }
  }

  _handleCustomerUpdated(data) {
    return this._updateFromStripeCustomer(data.object);
  }

  _handleCustomerDeleted(data) {
    const { object: customer } = data;

    return this.accountSubscriptionTable.retrieveByStripeCustomerId(customer.id)
      .then(({ Items: [accountSubscription] }) => {
        if (accountSubscription) {
          return this.accountSubscriptionTable.remove({ account_id: accountSubscription.account_id });
        }
      });
  }

  _overwriteFromStripeSubscription(subscription) {

    return this.accountSubscriptionTable.retrieveByStripeCustomerId(subscription.customer)
      .then(({ Items: [accountSubscription] }) => {

        if (!accountSubscription) {
          return this.stripeClient.customers.retrieve(subscription.customer)
            .then(customer => customer && customer.metadata.account_id);
        } else {
          return accountSubscription.account_id;
        }
      })
      .then(accountId => {
        return accountId && this.accountSubscriptionTable.create(_.pickBy({
          account_id: accountId,
          location_id: subscription.metadata.location_id,
          stripe_customer_id: subscription.customer,
          status: subscription.status,
          current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),           
          source_id: subscription.metadata.source_id || 'stripe',
          plan_id: subscription.plan.id,
          stripe_subscription_id: subscription.id
        }, prop => !_.isEmpty(prop)));
      });
  }

  _updateFromStripeSubscription(subscription) {

    return this.accountSubscriptionTable.retrieveByStripeCustomerId(subscription.customer)
      .then(({ Items: [accountSubscription] }) => {
        if (accountSubscription) {
          const { status, current_period_start, current_period_end, canceled_at, ended_at, cancel_at_period_end, plan: { id: plan_id }, id: stripe_subscription_id, metadata } = subscription;

          return this.accountSubscriptionTable.patch({ account_id: accountSubscription.account_id }, _.omitBy({
            status,
            plan_id,
            current_period_start: new Date(current_period_start * 1000).toISOString(),
            current_period_end: new Date(current_period_end * 1000).toISOString(),
            canceled_at: canceled_at && new Date(canceled_at * 1000).toISOString(),
            ended_at: ended_at && new Date(ended_at * 1000).toISOString(),
            cancel_at_period_end: cancel_at_period_end || false,
            stripe_subscription_id,
            location_id: metadata && metadata.location_id
          }, value => _.isNil(value)));
        }
      })
      .catch(err => {
         if (err.name === 'ConditionalCheckFailedException') {
          // Stale event, ignore
          console.log(JSON.stringify(subscription, null, 4));
          return Promise.resolve();
         } else {
          return Promise.reject(err);
         }
      });
  }

  _handleSubscriptionCreated(data) {
    if (!data.object.metadata.is_from_flo_user_portal) {
      return this._overwriteFromStripeSubscription(data.object);
    } else {
      return Promise.resolve();
    }
  }

  _handleSubscriptionUpdatedOrDeleted(data) {
    return this._updateFromStripeSubscription(data.object);
  }

  _updateStripeCustomerPaymentSource(stripeCustomerId, stripeToken) {
    return this.stripeClient.customers.update(stripeCustomerId, {
      source: stripeToken
    });
  }

  _createStripeCustomer(user, account, sourceId) {
    return this.stripeClient.customers.create({
      email: user.email,
      metadata: {
        account_id: account.id,
        source_id: sourceId,
        is_from_flo_user_portal: true
      }
    });
  }

  _ensureStripeCustomer(user, account, sourceId) {
    return this._retrieveStripeCustomerByEmail(user.email)
      .then(customer => {
        return customer ||
          this._createStripeCustomer(user, account, sourceId);
      });
  }

  _retrieveStripeCustomerByEmail(email) {
    return this.stripeClient.customers.list({ email })
      .then(({ data }) => data && data[0]);
  }

  _hasSubscriptionStatus(customer, statusTypes) {
    return (
      customer.subscriptions && 
      customer.subscriptions.data && 
      customer.subscriptions.data.some(({ status }) => 
        statusTypes.indexOf(status) >= 0
      )
    );
  }

  _willCancelAtPeriodEnd(customer) {
    return (
      customer.subscriptions &&
      customer.subscriptions.data &&
      customer.subscriptions.data.some(({ cancel_at_period_end }) => cancel_at_period_end)
    );
  }

  _hasActiveSubscription(customer) {
    return (
      this._hasSubscriptionStatus(
        customer,
        [TSubscriptionStatus.active, TSubscriptionStatus.trialing]
      )
    );
  }

  _hasPastDueSubscription(customer) {
    return this._hasSubscriptionStatus(
      customer,
      [TSubscriptionStatus.past_due]
    );
  }

  _hasUnpaidSubscription(customer) {
    return this._hasSubscriptionStatus(
      customer,
      [TSubscriptionStatus.unpaid]
    );
  }

  _hasPreviouslyCanceledSubscriptions(customer) {
    return this.stripeClient.subscriptions.list({
      customer: customer.id,
      status: 'canceled',
      limit: 1
    })
    .then(({ data }) => {
      return !!data.length;
    });
  }
}

export default new DIFactory(SubscriptionService, [UserAccountService, AccountService, LocationService, AuthorizationService, AccountSubscriptionTable, SubscriptionPlanTable, StripeClient, SubscriptionConfig]);