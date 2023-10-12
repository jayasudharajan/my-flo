package com.flo.notification.sdk.service

import java.time.{LocalDateTime, ZoneOffset}
import java.util.UUID

import com.flo.communication.KafkaProducer
import com.flo.notification.sdk.model.{Incident, AlarmSystemModeSettings, AlarmToAction, DeliverySettings, AlarmDeliverySettings, Filter, Severity, SupportOption, UserDeliverySettings, Action => ActionModel}
import com.flo.notification.sdk.model.kafka.AlarmIncident
import com.flo.notification.sdk.DbFixture
import com.flo.notification.sdk.util.RandomDataGeneratorUtil
import io.getquill.{MappedEncoding, SnakeCase}
import org.apache.kafka.clients.producer.RecordMetadata
import org.apache.kafka.common.TopicPartition
import org.scalamock.scalatest.AsyncMockFactory
import org.scalatest.{fixture, _}
import com.flo.notification.sdk.model.statistics.{Filter => StatisticsFilter}
import org.json4s.jackson.JsonMethods.parse
import org.json4s.jackson.Serialization

import scala.concurrent.Future

class NotificationServiceSpec extends fixture.AsyncWordSpec
  with Matchers with DbFixture with RandomDataGeneratorUtil with AsyncMockFactory with OptionValues {

  val recordMetadata = new RecordMetadata(new TopicPartition("test", 1), 10L, 100L, 433423L, 12322L, 1024, 1024)

  implicit val formats = org.json4s.DefaultFormats
  implicit val encodeJSON = MappedEncoding[Map[String, Any], String](jsonAsMap => Serialization.write(jsonAsMap))
  implicit val decodeJSON = MappedEncoding[String, Map[String, Any]](jsonAsStr => parse(jsonAsStr).extract[Map[String, Any]])


  "NotificationService" should {
    /*
    def createEventsWithDifferentStatus(copy: AlarmEvent => AlarmEvent)(implicit service: NotificationService): Future[List[AlarmEvent]] = {
      val randomAlert = random[AlarmEvent](3)

      def generateAlarm(randomIndex: Int, status: Int): AlarmEvent = copy(randomAlert(randomIndex).copy(status = status))

      val alarmEvent = generateAlarm(0, AlarmEventStatus.Received)
      val alarmEvent2 = generateAlarm(1, AlarmEventStatus.Resolved)
      val alarmEvent3 = generateAlarm(2, AlarmEventStatus.Triggered)

      val res = for {
        e1 <- service.createEvent(alarmEvent)
        e2 <- service.createEvent(alarmEvent2)
        e3 <- service.createEvent(alarmEvent3)
      } yield ()
      res.map(_ => {
        List(alarmEvent, alarmEvent2, alarmEvent3)
      })
    }

    def createAlarm(row: Alarm)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[Alarm] = {
      import ctx._
      val result = quote {
        query[Alarm].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    def createSettings(row: AlarmSystemModeSettings)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[AlarmSystemModeSettings] = {
      import ctx._
      val result = quote {
        query[AlarmSystemModeSettings].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    def createUserSettings(row: UserDeliverySettings)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[UserDeliverySettings] = {
      import ctx._
      val result = quote {
        query[UserDeliverySettings].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    def createSupportOptions(row: SupportOption)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[SupportOption] = {
      import ctx._
      val result = quote {
        query[SupportOption].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    def createAction(row: ActionModel)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[ActionModel] = {
      import ctx._
      val result = quote {
        query[ActionModel].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    def createAlarmToAction(row: AlarmToAction)(implicit ctx: PostgresAsyncContext[SnakeCase.type]): Future[AlarmToAction] = {
      import ctx._
      val result = quote {
        query[AlarmToAction].insert(liftCaseClass(row))
      }
      ctx.run(result).map(_ => row)
    }

    "retrieve alarms by filter" in { dbConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dbConfig)
      implicit val context = service.ctx
      val parentAlarm1 = random[Alarm].copy(id = 1, parentId = None)
      val parentAlarm2 = random[Alarm].copy(id = 2, parentId = None)
      val childAlarm1 = random[Alarm].copy(id = 3, parentId = Some(parentAlarm1.id))
      val childAlarm2 = random[Alarm].copy(id = 4, parentId = Some(parentAlarm1.id))

      Future.sequence(Seq(createAlarm(parentAlarm1), createAlarm(parentAlarm2), createAlarm(childAlarm1), createAlarm(childAlarm2))).flatMap { _ =>
        service.getAlarmsByFilter(None, None, None).map { alarms =>
          alarms should contain theSameElementsAs List(
            parentAlarm1.toModel(Map(parentAlarm1.id -> Set(childAlarm1.id, childAlarm2.id))),
            parentAlarm2.toModel(),
            childAlarm1.toModel(),
            childAlarm2.toModel()
          )
        }
      }
    }

    "send an alert" in { ctx =>
      val kafkaProducer = mock[KafkaProducer]
      var message: Option[AlarmIncident] = None

      (kafkaProducer.send[AlarmIncident] _) expects(*, *) onCall {
        (alarmIncident: AlarmIncident, _: AlarmIncident => String) => {
          message = Some(alarmIncident)
          recordMetadata
        }
      }

      val service = new NotificationService(kafkaProducer, ctx)
      val deviceId = "some-device"
      val alarmId = 55

      service.sendAlarm(deviceId, alarmId)

      message.isDefined shouldEqual true
      message.get.data.alarm.reason shouldEqual alarmId
      message.get.did shouldEqual deviceId
    }

    "retrieve an AlarmEvent by id" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val alarmEvent = random[AlarmEvent]
      val randomAlarm = random[Alarm].copy(parentId = None)

      implicit val context = service.ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        event <- service.createEvent(alarmEvent.copy(alarmId = alarm.id))
      } yield event

      result.flatMap(_ => {
        service.getAlarmEventById(alarmEvent.id)
          .map(x => x.get.event shouldEqual alarmEvent.copy(alarmId = randomAlarm.id))
      })
    }

    "delete an AlarmEvent by id" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      implicit val context = service.ctx

      val alarmEvent = random[AlarmEvent]
      val randomAlarm = random[Alarm].copy(parentId = None)

      val result = for {
        alarm <- createAlarm(randomAlarm)
        event <- service.createEvent(alarmEvent.copy(alarmId = alarm.id))
      } yield event

      result.flatMap(_ => {
        service.getAlarmEventById(alarmEvent.id).flatMap(x => {
          x.get.event shouldEqual alarmEvent.copy(alarmId = randomAlarm.id)
          service.deleteEventById(alarmEvent.id).flatMap(_ => {
            service.getAlarmEventById(alarmEvent.id).map(x => x shouldEqual None)
          })
        })
      })
    }

    "create event" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val alarmEvent = random[AlarmEvent]
      val randomAlarm = random[Alarm].copy(parentId = None)

      implicit val context = service.ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        event <- service.createEvent(alarmEvent.copy(alarmId = alarm.id))
      } yield event

      result.flatMap(event => {
        event shouldBe alarmEvent.copy(alarmId = randomAlarm.id)
        service.getAlarmEventById(alarmEvent.id).map {
          case Some(e) => e.event.createAt shouldEqual alarmEvent.createAt
          case None => assert(false)
        }
      })
    }

    "upsert event" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val randomAlarm = random[Alarm].copy(parentId = None)
      val alarmEvent = random[AlarmEvent].copy(alarmId = randomAlarm.id, reason = None)
      val filteredEvent = alarmEvent.copy(status = 2, reason = Some(13))

      implicit val context = service.ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        event <- service.upsertEvent(alarmEvent)
        updatedEvent <- service.upsertEvent(filteredEvent)
      } yield updatedEvent

      result.flatMap(success => {
        success shouldBe true
        service.getAlarmEventById(alarmEvent.id).map {
          case Some(e) =>
            e.event.status shouldEqual filteredEvent.status
            e.event.reason shouldEqual filteredEvent.reason
          case None => assert(false)
        }
      })
    }

    "update event" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val originalIcdc = UUID.randomUUID()
      val modifiedIcdc = UUID.randomUUID()

      val randomAlarm = random[Alarm].copy(parentId = None)

      implicit val context = ctx

      createAlarm(randomAlarm).flatMap(alarm => {

        val events = List(random[AlarmEvent], random[AlarmEvent], random[AlarmEvent]).zipWithIndex.map {
          case (event, index) => event.copy(icdId = originalIcdc, alarmId = alarm.id)
        }
        val result = Future.sequence(events.map(x => service.createEvent(x)))

        result.flatMap(_ => {
          val newEvents = events.slice(0, 2).map(x => x.copy(icdId = modifiedIcdc))

          service.updateEvents(newEvents).flatMap(success => {
            success shouldBe true
            val f = quote {
              query[AlarmEvent].filter(_.icdId == lift(modifiedIcdc))
            }
            ctx.run(f).map(x => {
              x.size shouldEqual 2
            })
          })
        })
      })
    }

    "retrieve latest alarm event" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val alarm = random[Alarm].copy(parentId = None)
      val alarmEvent1 = random[AlarmEvent].copy(alarmId = alarm.id, createAt = LocalDateTime.ofEpochSecond(0, 0, ZoneOffset.UTC))
      val alarmEvent2 = random[AlarmEvent].copy(alarmId = alarm.id, createAt = LocalDateTime.ofEpochSecond(1, 0, ZoneOffset.UTC))
      val alarmEvent3 = random[AlarmEvent].copy(alarmId = alarm.id, createAt = LocalDateTime.ofEpochSecond(2, 0, ZoneOffset.UTC))
      val alarmEvent4 = random[AlarmEvent].copy(alarmId = alarm.id, createAt = LocalDateTime.ofEpochSecond(3, 0, ZoneOffset.UTC))

      implicit val context = service.ctx

      val alarmsCreated = for {
        _ <- createAlarm(alarm)
        _ <- Future.sequence(Seq(service.createEvent(alarmEvent1), service.createEvent(alarmEvent2),
          service.createEvent(alarmEvent3), service.createEvent(alarmEvent4)))
      } yield ()

      alarmsCreated.flatMap { _ =>
        service.getLatestAlarmEvent(alarm.id).map { latestAlarmEvent =>
          latestAlarmEvent.value shouldEqual alarmEvent4
        }
      }
    }

    "retrieve latest snoozed alarm event" in { dataBaseConfig =>
      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val alarm = random[Alarm].copy(parentId = None)
      val alarmEvent1 = random[AlarmEvent].copy(alarmId = alarm.id, snoozeTo = Some(LocalDateTime.now),
        createAt = LocalDateTime.ofEpochSecond(0, 0, ZoneOffset.UTC))
      val alarmEvent2 = random[AlarmEvent].copy(alarmId = alarm.id, snoozeTo = Some(LocalDateTime.now),
        createAt = LocalDateTime.ofEpochSecond(1, 0, ZoneOffset.UTC))
      val alarmEvent3 = random[AlarmEvent].copy(alarmId = alarm.id, snoozeTo = Some(LocalDateTime.now),
        createAt = LocalDateTime.ofEpochSecond(2, 0, ZoneOffset.UTC))
      val alarmEvent4 = random[AlarmEvent].copy(alarmId = alarm.id, snoozeTo = None,
        createAt = LocalDateTime.ofEpochSecond(3, 0, ZoneOffset.UTC))

      implicit val context = service.ctx

      val alarmsCreated = for {
        _ <- createAlarm(alarm)
        _ <- Future.sequence(Seq(service.createEvent(alarmEvent1), service.createEvent(alarmEvent2),
          service.createEvent(alarmEvent3), service.createEvent(alarmEvent4)))
      } yield ()

      alarmsCreated.flatMap { _ =>
        service.getLatestSnoozedAlarmEvent(alarm.id).map { latestSnoozedAlarmEvent =>
          latestSnoozedAlarmEvent.value shouldEqual alarmEvent3
        }
      }
    }

    "clear events by icd" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      implicit val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val randomAlarm = random[Alarm].copy(parentId = None)
      val icdId = UUID.randomUUID()

      implicit val context = ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        events <- createEventsWithDifferentStatus(_.copy(alarmId = alarm.id, icdId = icdId))
      } yield events

      result.flatMap(events => {
        events.size shouldEqual 3
        service.clearEventsByIcd(randomAlarm.id, 3600, icdId).flatMap(success => {
          success shouldBe 1

          service.getAlarmEventById(events(2).id).flatMap(result => {
            result.get.event.status shouldEqual AlarmEventStatus.Resolved
            result.get.event.reason.value shouldEqual AlarmEventReason.Cleared
            result.get.event.snoozeTo.get.isAfter(LocalDateTime.now().plusSeconds(3595)) shouldBe true
            result.get.event.snoozeTo.get.isBefore(LocalDateTime.now().plusSeconds(3605)) shouldBe true
            val f = quote {
              query[AlarmEvent].filter(_.status == lift(AlarmEventStatus.Resolved))
            }
            ctx.run(f).map(x => {
              x.size shouldEqual 2
            })
          })
        })
      })
    }

    "clear events by location id" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      implicit val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val randomAlarm = random[Alarm].copy(parentId = None)
      val locationId = UUID.randomUUID()

      implicit val context = ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        events <- createEventsWithDifferentStatus(_.copy(alarmId = alarm.id, locationId = locationId))
      } yield events

      result.flatMap(events => {
        events.size shouldEqual 3
        service.clearEventsByLocation(randomAlarm.id, locationId, 3600).flatMap(success => {
          success shouldBe 1

          service.getAlarmEventById(events(2).id).flatMap(result => {
            result.get.event.status shouldEqual AlarmEventStatus.Resolved
            result.get.event.reason.value shouldEqual AlarmEventReason.Cleared
            result.get.event.snoozeTo.get.isAfter(LocalDateTime.now().plusSeconds(3595)) shouldBe true
            result.get.event.snoozeTo.get.isBefore(LocalDateTime.now().plusSeconds(3605)) shouldBe true
            val f = quote {
              query[AlarmEvent].filter(_.status == lift(AlarmEventStatus.Resolved))
            }
            ctx.run(f).map(x => {
              x.size shouldEqual 2
            })
          })
        })
      })
    }

    "clear all events without icdId parameter" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val now = LocalDateTime.now()

      val icdId1 = UUID.randomUUID()
      val icdId2 = UUID.randomUUID()

      val locationId = UUID.randomUUID()
      val accountId = UUID.randomUUID()

      val dataValues = Map("efd" -> 3, "fr" -> 0)
      val event1 = AlarmEvent(UUID.randomUUID(), 1, icdId1, AlarmEventStatus.Triggered, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)
      val event2 = AlarmEvent(UUID.randomUUID(), 2, icdId2, AlarmEventStatus.Triggered, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)
      val event3 = AlarmEvent(UUID.randomUUID(), 3, icdId2, AlarmEventStatus.Triggered, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)

      val randomAlarm = random[Alarm](3).map(_.copy(parentId = None))

      implicit val context = ctx

      val result = for {
        a1 <- createAlarm(randomAlarm(0))
        a2 <- createAlarm(randomAlarm(1))
        a3 <- createAlarm(randomAlarm(2))
        e1 <- service.createEvent(event1.copy(alarmId = a1.id))
        e2 <- service.createEvent(event2.copy(alarmId = a2.id))
        e3 <- service.createEvent(event3.copy(alarmId = a3.id))
      } yield ()

      result.flatMap(_ => {
        service.clearEvents(List(randomAlarm(0).id, randomAlarm(1).id, randomAlarm(2).id), locationId).flatMap(cleared => {
          cleared shouldBe 3

          val f = quote {
            query[AlarmEvent].filter { alarmEvent =>
              alarmEvent.status == lift(AlarmEventStatus.Resolved) &&
              alarmEvent.reason == lift(Option(AlarmEventReason.Cleared))
            }
          }
          ctx.run(f).map(x => {
            x.size shouldEqual 3
          })
        })
      })
    }

    "clear all events with icdId parameter" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val icdId1 = UUID.randomUUID()
      val icdId2 = UUID.randomUUID()

      val locationId = UUID.randomUUID()
      val now = LocalDateTime.now()
      val accountId = UUID.randomUUID()

      val dataValues = Map("efd" -> 3, "fr" -> 0)
      val event1 = AlarmEvent(UUID.randomUUID(), 1, icdId1, AlarmEventStatus.Received, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)
      val event2 = AlarmEvent(UUID.randomUUID(), 2, icdId2, AlarmEventStatus.Triggered, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)
      val event3 = AlarmEvent(UUID.randomUUID(), 3, icdId2, AlarmEventStatus.Triggered, None, None, locationId, 1, accountId, dataValues, "", "", None, None, "", now, now)

      val randomAlarm = random[Alarm](3).map(_.copy(parentId = None))

      implicit val context = ctx

      val result = for {
        a1 <- createAlarm(randomAlarm(0))
        a2 <- createAlarm(randomAlarm(1))
        a3 <- createAlarm(randomAlarm(2))
        e1 <- service.createEvent(event1.copy(alarmId = a1.id))
        e2 <- service.createEvent(event2.copy(alarmId = a2.id))
        e3 <- service.createEvent(event3.copy(alarmId = a3.id))
      } yield ()

      result.flatMap(_ => {
        service.clearEvents(List(randomAlarm(0).id, randomAlarm(1).id, randomAlarm(2).id), locationId, Some(icdId2)).flatMap(cleared => {
          cleared shouldBe 2

          val f = quote {
            query[AlarmEvent].filter { alarmEvent =>
              alarmEvent.status == lift(AlarmEventStatus.Resolved) &&
              alarmEvent.reason == lift(Option(AlarmEventReason.Cleared))
            }
          }
          ctx.run(f).map(x => {
            x.size shouldEqual 2
          })
        })
      })
    }

    "get default delivery settings (from system mode settings)" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx

      val randomAlarm = random[Alarm].copy(isInternal = false, parentId = None)

      implicit val context = ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        settings1 <- createSettings(AlarmSystemModeSettings(1, alarm.id, 0, Some(true), Some(true), Some(false), None))
        settings2 <- createSettings(AlarmSystemModeSettings(2, alarm.id, 1, Some(true), None, Some(false), None))
        settings3 <- createSettings(AlarmSystemModeSettings(3, alarm.id, 2, Some(false), Some(true), Some(false), Some(true)))
      } yield (alarm, settings1, settings2, settings3)

      val userWithNoSettings = UUID.randomUUID()
      val deviceWithNoSettings = UUID.randomUUID()

      result.flatMap(_ => {
        service.getDeliverySettings(userWithNoSettings, deviceWithNoSettings).map(settings => {
          settings.map(it => {
            it.name shouldEqual randomAlarm.name
            if (it.systemMode == 0) {
              it.settings.smsEnabled shouldEqual Some(true)
              it.settings.emailEnabled shouldEqual Some(true)
              it.settings.pushEnabled shouldEqual Some(false)
              it.settings.callEnabled shouldEqual None
            }
          })
          settings.size shouldEqual 3
        })
      })
    }

    "get user delivery settings" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx

      val randomAlarm = random[Alarm].copy(isInternal = false, parentId = None)
      val accountId = UUID.randomUUID()
      val userId = UUID.randomUUID()
      val locationId = UUID.randomUUID()
      val icdId = UUID.randomUUID()
      val userSettings = UserDeliverySettings(UUID.randomUUID(), accountId, userId, locationId, icdId, 1,
        DeliverySettings(None, Some(true), Some(false), None))

      implicit val context = ctx

      val result = for {
        alarm <- createAlarm(randomAlarm)
        settings1 <- createSettings(AlarmSystemModeSettings(1, alarm.id, 0, Some(true), Some(true), Some(false), None))
        settings2 <- createSettings(AlarmSystemModeSettings(2, alarm.id, 1, Some(true), None, Some(false), None))
        settings3 <- createSettings(AlarmSystemModeSettings(3, alarm.id, 2, Some(false), Some(true), Some(false), Some(true)))
        userSettings <- createUserSettings(userSettings)
      } yield (alarm, settings1, settings2, settings3, userSettings)

      result.flatMap(_ => {
        service.getDeliverySettings(userSettings.userId, userSettings.icdId).map(settings => {
          settings.map(it => {
            it.name shouldEqual randomAlarm.name
            if (it.systemMode == 0) {
              it.settings.smsEnabled shouldEqual userSettings.settings.smsEnabled
              it.settings.emailEnabled shouldEqual userSettings.settings.emailEnabled
              it.settings.pushEnabled shouldEqual userSettings.settings.pushEnabled
              it.settings.callEnabled shouldEqual userSettings.settings.callEnabled
            } else if (it.systemMode == 1) {
              it.settings.smsEnabled shouldEqual Some(true)
              it.settings.emailEnabled shouldEqual None
              it.settings.pushEnabled shouldEqual Some(false)
              it.settings.callEnabled shouldEqual None
            }
          })
          settings.size shouldEqual 3
        })
      })
    }

    "save new user delivery settings" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx

      val randomAlarm = random[Alarm].copy(isInternal = false, parentId = None)

      implicit val context = ctx
      val userId = UUID.randomUUID()
      val icdId = UUID.randomUUID()
      val locationId = UUID.randomUUID()
      val accountId = UUID.randomUUID()
      val Seq(defaultSet1, defaultSet2, defaultSet3) = random[DeliverySettings](3)
      val userSettings1 = defaultSet1.copy(emailEnabled = defaultSet1.emailEnabled.map(!_))
      val userSettings2 = defaultSet2.copy(emailEnabled = defaultSet2.pushEnabled.map(!_))

      val result = for {
        alarm <- createAlarm(randomAlarm)
        settings1 <- createSettings(
          AlarmSystemModeSettings(1, alarm.id, 0, defaultSet1.smsEnabled, defaultSet1.emailEnabled, defaultSet1.pushEnabled, defaultSet1.callEnabled))
        settings2 <- createSettings(
          AlarmSystemModeSettings(2, alarm.id, 1, defaultSet2.smsEnabled, defaultSet2.emailEnabled, defaultSet2.pushEnabled, defaultSet2.callEnabled))
        settings3 <- createSettings(
          AlarmSystemModeSettings(3, alarm.id, 2, defaultSet3.smsEnabled, defaultSet3.emailEnabled, defaultSet3.pushEnabled, defaultSet3.callEnabled))
        userSettings <- service.saveDeliverySettings(userId, accountId, List(
          DeviceAlarmDeliverySettings(icdId, locationId, alarm.id, 0, userSettings1),
          DeviceAlarmDeliverySettings(icdId, locationId, alarm.id, 1, userSettings2)
        ))
      } yield (alarm, settings1, settings2, settings3, userSettings)

      result.flatMap(_ => {
        service.getDeliverySettings(userId, icdId).map(settings => {
          settings.map(it => {

            if (it.systemMode == 0) {
              it.settings.smsEnabled shouldEqual userSettings1.smsEnabled
              it.settings.emailEnabled shouldEqual userSettings1.emailEnabled
              it.settings.pushEnabled shouldEqual userSettings1.pushEnabled
              it.settings.callEnabled shouldEqual userSettings1.callEnabled
            } else if (it.systemMode == 1) {
              it.settings.smsEnabled shouldEqual userSettings2.smsEnabled
              it.settings.emailEnabled shouldEqual userSettings2.emailEnabled
              it.settings.pushEnabled shouldEqual userSettings2.pushEnabled
              it.settings.callEnabled shouldEqual userSettings2.callEnabled
            } else if (it.systemMode == 3) {
              it.settings.smsEnabled shouldEqual defaultSet3.smsEnabled
              it.settings.emailEnabled shouldEqual defaultSet3.emailEnabled
              it.settings.pushEnabled shouldEqual defaultSet3.pushEnabled
              it.settings.callEnabled shouldEqual defaultSet3.callEnabled
            }
          })
          settings.size shouldEqual 3
        })
      })
    }

    "update user delivery settings" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      import ctx._
      val randomAlarm = random[Alarm].copy(isInternal = false, parentId = None)

      implicit val context = ctx
      val userId = UUID.randomUUID()
      val icdId = UUID.randomUUID()
      val locationId = UUID.randomUUID()
      val accountId = UUID.randomUUID()
      val Seq(deliverySettings1, deliverySettings2, deliverySettings3) = random[DeliverySettings](3)

      val result = for {
        alarm <- createAlarm(randomAlarm)
        settings1 <- createSettings(AlarmSystemModeSettings(1, alarm.id, 0, Some(true), Some(true), Some(false), None))
        settings2 <- createSettings(AlarmSystemModeSettings(2, alarm.id, 1, Some(true), None, Some(false), None))
        settings3 <- createSettings(AlarmSystemModeSettings(3, alarm.id, 2, Some(false), Some(true), Some(false), Some(true)))
        userSettings <- service.saveDeliverySettings(userId, accountId, List(
          DeviceAlarmDeliverySettings(icdId, locationId, alarm.id, 0, deliverySettings1),
          DeviceAlarmDeliverySettings(icdId, locationId, alarm.id, 1, deliverySettings2)
        ))
      } yield (alarm, settings1, settings2, settings3, userSettings)

      result.flatMap(_ => {

        service.saveDeliverySettings(userId, accountId, List(
          DeviceAlarmDeliverySettings(icdId, locationId, randomAlarm.id, 0, deliverySettings3)
        )).flatMap(_ => {
          service.getDeliverySettings(userId, icdId).flatMap(settings => {

            settings
              .find(_.systemMode == 0)
              .map(it => {
                it.settings.smsEnabled shouldEqual deliverySettings3.smsEnabled
                it.settings.emailEnabled shouldEqual deliverySettings3.emailEnabled
                it.settings.pushEnabled shouldEqual deliverySettings3.pushEnabled
                it.settings.callEnabled shouldEqual None
              })

            settings.size shouldEqual 3

            val f = quote {
              query[UserDeliverySettings]
            }

            ctx.run(f).map(x => x.size shouldEqual 2)
          })
        })
      })
    }

    "retrieve alarm events by filter" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      implicit val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      val randomAlarm = random[Alarm].copy(isInternal = false, parentId = None)

      implicit val context = ctx
      val result = for {
        alarm <- createAlarm(randomAlarm)
        events <- createEventsWithDifferentStatus(_.copy(alarmId = alarm.id))
      } yield events

      result.flatMap(events => {
        events.size shouldEqual 3

        val filteredEvents = service.getAlarmEventsByFilter(
          icdIds = events.map(_.icdId),
          locationIds = Seq(),
          status = List(Filter[Int]("eq", AlarmEventStatus.Received)),
          createdAt = List(Filter[LocalDateTime]("gt", events.head.createAt.minusSeconds(1)))
        )

        filteredEvents.map(x => {
          x.items.length shouldEqual 1
        })
      })
    }

    "get alert actions and support options" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx
      implicit val context = ctx

      val randomAlarm = random[Alarm](4).map(_.copy(parentId = None))
      val supportOptions = random[SupportOption](4)
      val action1 = ActionModel(1, "Closed Valve", "Valve has been closed", 1, 1)
      val action2 = ActionModel(2, "Snooze", "Snooze", 1, 1)

      val result = for {
        a1    <- createAlarm(randomAlarm(0))
        a2    <- createAlarm(randomAlarm(1))
        a3    <- createAlarm(randomAlarm(2))
        a4    <- createAlarm(randomAlarm(3))
        s1    <- createSupportOptions(supportOptions(0).copy(alarmId = a1.id))
        s2    <- createSupportOptions(supportOptions(1).copy(alarmId = a2.id))
        s3    <- createSupportOptions(supportOptions(2).copy(alarmId = a2.id))
        ac1   <- createAction(action1)
        ac2   <- createAction(action2)
        ata1  <- createAlarmToAction(AlarmToAction(a1.id, ac1.id))
        ata2  <- createAlarmToAction(AlarmToAction(a1.id, ac2.id))
        ata3  <- createAlarmToAction(AlarmToAction(a2.id, ac1.id))
        ata4  <- createAlarmToAction(AlarmToAction(a2.id, ac2.id))
        ata5  <- createAlarmToAction(AlarmToAction(a3.id, ac2.id))
      } yield (a1, a2, a3, a4, s1, s2, s3, ac1, ac2, ata1, ata2, ata3, ata4, ata5)

      result.flatMap(_ => {
        service.getAlertActionsAndSupportOptions.flatMap(res => {
          res.foreach(it => {
            if (it.alarmId == randomAlarm(0).id) {
              it.supportOptions.size shouldEqual 1
              it.actions.size shouldEqual 2
            }
            if (it.alarmId == randomAlarm(1).id) {
              it.supportOptions.size shouldEqual 2
              it.actions.size shouldEqual 2
            }
          })
          res.size shouldEqual 4
        })
      })
    }

    "retrieve statistics" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      implicit val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx

      val randomAlarm = random[Alarm](3).map(_.copy(parentId = None))
      val criticalAlarm = randomAlarm(0).copy(severity = Severity.Critical, parentId = None)
      val warningAlarm = randomAlarm(1).copy(severity = Severity.Warning, parentId = None)
      val infoAlarm = randomAlarm(2).copy(severity = Severity.Info, parentId = None)

      val randomEvent = random[AlarmEvent](7)

      val icdId = UUID.randomUUID()
      val date1 = LocalDateTime.now()
      val date2 = LocalDateTime.now().plusDays(1)
      val date3 = LocalDateTime.now().plusDays(2)
      val date4 = LocalDateTime.now().plusDays(10)
      val event1 = randomEvent(0) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date3)
      val event2 = randomEvent(1) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date2)
      val event3 = randomEvent(2) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Resolved, updateAt = date1)
      val event4 = randomEvent(3) copy (alarmId = warningAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date3)
      val event5 = randomEvent(4) copy (alarmId = warningAlarm.id, icdId = icdId, status = AlarmEventStatus.Resolved, updateAt = date2)
      val event6 = randomEvent(5) copy (alarmId = warningAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date1)
      val event7 = randomEvent(6) copy (alarmId = infoAlarm.id, icdId = icdId, status = AlarmEventStatus.Resolved, updateAt = date4)

      implicit val context = ctx
      val result = for {
        critical <- createAlarm(criticalAlarm)
        warning <- createAlarm(warningAlarm)
        info <- createAlarm(infoAlarm)
        e1 <- service.createEvent(event1)
        e2 <- service.createEvent(event2)
        e3 <- service.createEvent(event3)
        e4 <- service.createEvent(event4.copy(alarmId = warning.id))
        e5 <- service.createEvent(event5.copy(alarmId = warning.id))
        e6 <- service.createEvent(event6.copy(alarmId = warning.id))
        e7 <- service.createEvent(event7.copy(alarmId = info.id))
      } yield (critical, warning, info, e1, e2, e3, e4, e5, e6, e7)

      result.flatMap(_ => {

        val statistics = service.retrieveStatistics(StatisticsFilter(None, None, None, None, None))

        statistics.map(x => {
          x.warning shouldEqual 1
          x.info shouldEqual 0
          x.critical shouldEqual 2
        })
      })
    }

    "retrieve statistics by filters" in { dataBaseConfig =>

      val kafkaProducer = mock[KafkaProducer]
      implicit val service = new NotificationService(kafkaProducer, dataBaseConfig)
      val ctx = service.ctx

      val randomAlarm = random[Alarm](3).map(_.copy(parentId = None))
      val criticalAlarm = randomAlarm(0).copy(severity = Severity.Critical)
      val warningAlarm = randomAlarm(1).copy(severity = Severity.Warning)
      val infoAlarm = randomAlarm(2).copy(severity = Severity.Info)

      val randomEvent = random[AlarmEvent](7)

      val icdId = UUID.randomUUID()
      val icdId2 = UUID.randomUUID()
      val date1 = LocalDateTime.now()
      val date2 = LocalDateTime.now().plusDays(1)
      val date3 = LocalDateTime.now().plusDays(2)
      val event1 = randomEvent(0) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date3)
      val event2 = randomEvent(1) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Triggered, updateAt = date2)
      val event3 = randomEvent(2) copy (alarmId = criticalAlarm.id, icdId = icdId, status = AlarmEventStatus.Resolved, updateAt = date1)
      val event4 = randomEvent(3) copy (alarmId = warningAlarm.id, icdId = icdId2, status = AlarmEventStatus.Triggered, updateAt = date3)
      val event5 = randomEvent(4) copy (alarmId = warningAlarm.id, icdId = icdId2, status = AlarmEventStatus.Resolved, updateAt = date2)
      val event6 = randomEvent(5) copy (alarmId = warningAlarm.id, icdId = icdId2, status = AlarmEventStatus.Triggered, updateAt = date1)

      implicit val context = ctx
      val result = for {
        critical <- createAlarm(criticalAlarm)
        warning <- createAlarm(warningAlarm)
        info <- createAlarm(infoAlarm)
        e1 <- service.createEvent(event1)
        e2 <- service.createEvent(event2)
        e3 <- service.createEvent(event3)
        e4 <- service.createEvent(event4.copy(alarmId = warning.id))
        e5 <- service.createEvent(event5.copy(alarmId = warning.id))
        e6 <- service.createEvent(event6.copy(alarmId = warning.id))
      } yield (critical, warning, info, e1, e2, e3, e4, e5, e6)

      result.flatMap(_ => {

        val statistics = service.retrieveStatistics(StatisticsFilter(None, Some(date3.minusHours(1)), None, None, Some(icdId)))

        statistics.map(x => {
          x.warning shouldEqual 0
          x.info shouldEqual 0
          x.critical shouldEqual 1
        })
      })
    }*/
  }
}