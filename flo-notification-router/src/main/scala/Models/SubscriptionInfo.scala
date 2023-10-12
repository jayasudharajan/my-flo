package Models

import com.flo.Models.{AccountSubscription, SubscriptionPlan}

case class SubscriptionInfo(
                             subscription: AccountSubscription,
                             subscriptionPlan: SubscriptionPlan
                           ) {}
