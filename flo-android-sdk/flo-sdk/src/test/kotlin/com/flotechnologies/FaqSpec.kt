package com.flotechnologies;

import kotlinx.serialization.json.Json
import org.amshove.kluent.shouldEqual
import org.assertj.core.api.Assertions.assertThat
import org.jetbrains.spek.api.Spek
import kotlin.jvm.javaClass

class FaqSpec : Spek({
    describe("FaqModel") {
        it("should be parsed faq.json") {
            var faq = Json.nonstrict.parse(Faq.serializer(), javaClass.classLoader.getResourceAsStream("faq.json")!!.reader().readText())
            assertThat(faq.created).isEqualTo("1465187755")
            assertThat(faq.questions!!.size).isEqualTo(11)
        }
        it("should be passed") {
            val a: MutableList<String> = mutableListOf()
            a.count() `shouldEqual` 0
            a.isEmpty() `shouldEqual` true
            a.isNotEmpty() `shouldEqual` false
            a.add("")
            a.count() `shouldEqual` 1
            a.isEmpty() `shouldEqual` false
            a.isNotEmpty() `shouldEqual` true
        }
    }
})

