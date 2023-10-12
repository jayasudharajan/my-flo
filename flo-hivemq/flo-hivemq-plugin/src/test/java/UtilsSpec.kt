package com.flotechnologies

import com.flotechnologies.service.FirebaseService
import com.flotechnologies.util.DataSnapshots
import com.flotechnologies.util.Futurese
import com.flotechnologies.util.Maps
import com.flotechnologies.util.Optionals
import com.google.firebase.database.DataSnapshot
import com.nhaarman.mockito_kotlin.whenever
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.describe
import org.jetbrains.spek.api.dsl.it
import org.junit.platform.runner.JUnitPlatform
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.mockito.Mockito




@RunWith(JUnitPlatform::class)
class UtilsSpec : Spek({
    describe("Optionals") {
        it("should be java utils Optional") {
            assertThat(Optionals.toJavaUtil(com.google.common.base.Optional.of(1)).get()).isEqualTo(1)
            assertThat(Optionals.toJavaUtil(com.google.common.base.Optional.of(1)).isPresent()).isTrue()
        }
    }

    describe("DataSnapshots") {
        it("should be null") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(null)
            assertThat(DataSnapshots.getValueTesting(Object::class.java, dataSnapshot)).isEqualTo(null)
            assertThatThrownBy({ DataSnapshots.getValueOrThrowTesting(Object::class.java, dataSnapshot) })
                    .isInstanceOf(NullPointerException::class.java)
        }

        it("should not be null") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn("")
            assertThat(DataSnapshots.getValueTesting(String::class.java, dataSnapshot)).isEqualTo("")
            assertThat(DataSnapshots.getValueOrThrowTesting(String::class.java, dataSnapshot)).isEqualTo("")
        }

        it("should throw casting exception") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(0L)
            assertThatThrownBy({ DataSnapshots.getString(dataSnapshot) })
                    .isInstanceOf(ClassCastException::class.java)
        }

        it("should be default") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(null)
            assertThat(DataSnapshots.getValue(dataSnapshot, true)).isEqualTo(true)
            assertThat(DataSnapshots.getValue(dataSnapshot, "")).isEqualTo("")
            assertThat(DataSnapshots.getValue(dataSnapshot, 0L)).isEqualTo(0L)
            assertThat(DataSnapshots.getValue(dataSnapshot, 0.0)).isEqualTo(0.0)
            val map: Map<String, Any> = hashMapOf("" to 0)
            val list: List<Any> = listOf(0)
            assertThat(DataSnapshots.getValue(dataSnapshot, map)).isEqualTo(map)
            assertThat(DataSnapshots.getValue(dataSnapshot, list)).isEqualTo(list)
        }

        it("should be boolean") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(true)
            assertThat(DataSnapshots.getBoolean(dataSnapshot)).isEqualTo(true)
            assertThat(DataSnapshots.getBooleanOrThrow(dataSnapshot)).isEqualTo(true)
            assertThat(DataSnapshots.getValue(dataSnapshot, false)).isEqualTo(true)
        }

        it("should be long") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(0L)
            assertThat(DataSnapshots.getLong(dataSnapshot)).isEqualTo(0L)
            assertThat(DataSnapshots.getLongOrThrow(dataSnapshot)).isEqualTo(0L)
            assertThat(DataSnapshots.getValue(dataSnapshot, 1L)).isEqualTo(0L)
        }

        it("should be double") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn(0.0)
            assertThat(DataSnapshots.getDouble(dataSnapshot)).isEqualTo(0.0)
            assertThat(DataSnapshots.getDoubleOrThrow(dataSnapshot)).isEqualTo(0.0)
            assertThat(DataSnapshots.getValue(dataSnapshot, 1.0)).isEqualTo(0.0)
        }

        it("should be String") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            whenever(dataSnapshot.getValue()).thenReturn("")
            assertThat(DataSnapshots.getString(dataSnapshot)).isEqualTo("")
            assertThat(DataSnapshots.getValue(dataSnapshot, "foo")).isEqualTo("")
        }

        it("should be Map") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            val map: Map<String, Any> = hashMapOf("" to 0)
            val default: Map<String, Any> = hashMapOf("" to 1)
            whenever(dataSnapshot.getValue()).thenReturn(map)
            assertThat(DataSnapshots.getMap(dataSnapshot)).isEqualTo(map)
            assertThat(DataSnapshots.getValue(dataSnapshot, default)).isEqualTo(map)
        }

        it("should be List") {
            val dataSnapshot = mock(DataSnapshot::class.java)
            val list: List<Any> = listOf(0)
            val default: List<Any> = listOf(1)
            whenever(dataSnapshot.getValue()).thenReturn(list)
            assertThat(DataSnapshots.getList(dataSnapshot)).isEqualTo(list)
            assertThat(DataSnapshots.getValue(dataSnapshot, default)).isEqualTo(list)
        }
    }

    describe("Maps") {
        it("should put and putIfNotNull") {
            val map: Map<String, Int?> = hashMapOf("" to 0)
            assertThat(Maps.put(map, "1", 1).get("1")).isEqualTo(1)
            assertThat(Maps.putIfNotNull(map, "2", null).containsKey("2")).isFalse()
            assertThat(Maps.putIfNotNull(map, "3", 3).containsKey("3")).isTrue()
        }
    }

    describe("Maps.Builder") {
        it("should put and putIfNotNull fluently") {
            val map: Map<String, Int?> = hashMapOf("" to 0)
            assertThat(Maps.Builder.of(map).put("1", 1).get().get("1")).isEqualTo(1)
            assertThat(Maps.Builder.of(map).putIfNotNull("2", null).get().containsKey("2")).isFalse()
            assertThat(Maps.Builder.of(map).putIfNotNull("3", 3).get().containsKey("3")).isTrue()
        }
    }

    describe("Futurese") {
        //it("should ") {
            //val future = Mockito.mock(ResultFuture::class.java)
            //whenever()
            //Mockito.doReturn(result).`when`<Any>(future).get()
            //Mockito.doReturn(future).`when`<Any>(session).executeAsync(Mockito.anyString())
            //Mockito.doReturn(true).`when`<Any>(future).isDone()
            //Futurese.addCallback({ Future })
        //}
    }
})
