# Task scheduler

Task scheduler service based on [Redisson](https://redisson.org) scheduler service.

Table of contents
=================

  * [Commands](#commands)
    * [Scheduling a Task](#scheduling-a-task)
    * [Cancel Task](#cancel-task)
    * [Suspend Task](#suspend-task)
    * [Resume Task](#resume-task)
    * [Suspend all Tasks](#suspend-all-tasks)
    * [Resume all Tasks](#resume-all-tasks)
    * [Scheduling a Task](#scheduling-a-task)
  * [Troubleshooting and debugging](#troubleshooting-and-debugging)

# Commands

## Scheduling a Task

To schedule a new task you should send a message to the Kafka topic defined by the enviroment variable `TASKS_KAFKA_TOPIC`. **By default the you can not schedule two task with same id if the first one is still to be executed, see the should_override field for that.** 

The message to be sent must follow this structure:

- `destination_topic`: **[String]** *[required]* the name of the topic to foward the message defined on `task_data` field.
- `task_data`: **[String]** *[required]* used to store a message to be fowarded. This should be a json if destination topic is not encrypted and a cipher text if encrypted.
- `schedule`: **[Schedule]** *[required]*, representing the schedule of the task used to execute it containing the following fields:
    - `id`: **[String]** *[required]* representing an uuid that could be used to execute actions over the scheduled task like pause, resume or cancel.
    - `name`: **[String]** *[optional]* used to give a name to the task schedule.
    - `expression` - **[String]** *[required]* a valid [Quartz' CronExpression](http://quartz-scheduler.org/api/2.1.7/org/quartz/CronExpression.html),
which describes when this job should trigger. e.g. `expression = "*/30 * * ? * *"` would fire every 30 seconds, on every date (however,
the firing schedule created by this expression is modified by the `calendar` variable, defined below)
    - `timezone` - **[String]** *[required]*  the timezone in which to execute the schedule.
must be parseable by [`java.util.TimeZone.getTimeZone()`](http://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html#getTimeZone(java.lang.String))
- `should_override`: **[Boolean]** *[optional]* indicates if should override a task with same id will be executed.

Json example:

```
{
  "destination_topic":"sms",
  "task_data":"{ \"id\": \"dsd\" }",
  "schedule":{
    "id":"9abfb3d7-6ab9-404d-937e-216e90352d59",
    "name":"test-schedule",
    "expression":"*/50 * * ? * *",
    "timezone":"America/Argentina/Buenos_Aires"
    }
}
```

> Known issue: timezone is ignored now, service will expect dates in cron expresion in etc/UTC timezone. Consumer is  responsible to convert it for now.

## Cancel Task
To cancel an already scheduled task you should send a JSON message to the Kafka topic defined by the enviroment variable `SCHEDULER_COMMANDS_KAFKA_TOPIC`.

The message to be sent must follow this structure:

- `action`: **[String]** *[required]* the name of action to be executed. The valid actions are: cancel, suspend, suspend-all, resume and resume-all.
- `task_id`: **[String]** *[required]* uuid used on the schedule object when task was scheduled.

Json example:

```
{
    "action": "cancel",
    "task_id": "9abfb3d7-6ab9-404d-937e-216e90352d59"
}
```

## Suspend Task
To suspend an already scheduled task you should send a JSON message to the Kafka topic defined by the enviroment variable `SCHEDULER_COMMANDS_KAFKA_TOPIC`.

The message to be sent must follow this structure:

- `action`: **[String]** *[required]* the name of action to be executed. The valid actions are: cancel, suspend, suspend-all, resume and resume-all.
- `task_id`: **[String]** *[required]* uuid used on the schedule object when task was scheduled.

Json example:

```
{
    "action": "suspend",
    "task_id": "9abfb3d7-6ab9-404d-937e-216e90352d59"
}
```

## Resume Task
To resumen a previously suspended task you should send a JSON message to the Kafka topic defined by the enviroment variable `SCHEDULER_COMMANDS_KAFKA_TOPIC`.

The message to be sent must follow this structure:

- `action`: **[String]** *[required]* the name of action to be executed. The valid actions are: cancel, suspend, suspend-all, resume and resume-all.
- `task_id`: **[String]** *[required]* uuid used on the schedule object when task was scheduled.

Json example:

```
{
    "action": "suspend",
    "task_id": "9abfb3d7-6ab9-404d-937e-216e90352d59"
}
```

## Suspend all Tasks

To suspend all running tasks you should send a JSON message to the Kafka topic defined by the enviroment variable `SCHEDULER_COMMANDS_KAFKA_TOPIC`.

The message to be sent must follow this structure:

- `action`: **[String]** *[required]* the name of action to be executed. The valid actions are: cancel, suspend, suspend-all, resume and resume-all.

Json example:

```
{
    "action": "suspend-all"
}
```

## Resume all Tasks

To resume all suspended tasks you should send a JSON message to the Kafka topic defined by the enviroment variable `SCHEDULER_COMMANDS_KAFKA_TOPIC`.

The message to be sent must follow this structure:

- `action`: **[String]** *[required]* the name of action to be executed. The valid actions are: cancel, suspend, suspend-all, resume and resume-all.

Json example:

```
{
    "action": "resume-all"
}
```

# Troubleshooting and debugging

In case of service outage or incorrect behavior please check this first:

- Check tasks messages are arriving to topic defined in `TASKS_KAFKA_TOPIC`
- Check that commands (cancel, suspend, resume, suspend-all and resume-all) are arriving to topic defined in the env var `SCHEDULER_COMMANDS_KAFKA_TOPIC`
- Check that incoming message are deserializing properly: search in kibana phrase "Error when trying to deserialize message." for task-scheduler service. If no match is found then deserialization is working but if you see some error the could be happening two things:
    - Decryption is failing: you can try to decrypt it using nodejs or scala library
    - Json format is not the right one: you will need to decrypt it like described in previous item and then see if json is correct comparing with the examples defined previously
- Check if Redis instance defined in env var REDIS_HOST:6379 is up and working. Use redis-cli to check it, try to create a new key and delete it.
- Check status of topic defined in destination-topic. Put something using console producer and check if it is received in the console consumer. Should the destination topic be decrypted/encrypted? Is a data field decrypted/encrypted?

At this point you had checked all satellites systems and boundaries in the service. If they are working, next step is to see inner workings.

Logs are always your friend, check errors in kibana for task scheduler service. If there is no error recently check if tasks logs in DyanamoDB table {dev|stg|prod}_TaskSchedulerLog, this table show you the state changes for tasks.

- Every time that a task is schedule you should find in logs this messages: "Scheduling task: ${taskId}", s"Task ${taskId} was scheduled." and "Task scheduled: ${taskId}" 
- Every time that a command is executed schedule you should find in logs messages like: "Task ${taskId} was canceled|suspended|resumed." or "All tasks were suspended|resumed."

If at this point you do not find something, you can try to disable encryption and put in the kafka topic a test task like this one:

```
{ 
    "destination_topic": "task-scheduler-test", 
    "task_data": "Hello!!!", 
    "schedule": { 
        "id": "9abfb3d7-6ab9-404d-937e-216e90352d63", 
        "expression": "*/10 * * ? * *", 
        "timezone":"Etc/UTC" 
     }
 }
```

That will put a "Hello!!!" in "task-scheduler-test" kafka topic every 10 secs. So make sure that this topic exists and use the console consumer to see if those messages are arriving to the topic. 

If that does not work, then could be a new issue. You can try to see previous versions and perhaps rollback to a previous one. Just make sure to create a new issue in GitHub so the maintainers are notified.
