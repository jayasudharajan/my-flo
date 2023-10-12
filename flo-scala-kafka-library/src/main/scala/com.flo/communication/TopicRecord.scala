package com.flo.communication

import org.joda.time.DateTime

/**
  * Created by facundo on 26/1/17.
  */
case class TopicRecord[T](data: T, createdAt: DateTime)
