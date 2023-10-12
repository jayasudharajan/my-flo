package com.flotechnologies.annotations;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.util.Collection;

import javax.annotation.meta.TypeQualifier;
import javax.annotation.meta.TypeQualifierValidator;
import javax.annotation.meta.When;

@Documented
@TypeQualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface NonEmpty {
    When when() default When.ALWAYS;

    public static class Checker implements TypeQualifierValidator<NonEmpty> {
        public Checker() {
        }

        @Override
        public When forConstantValue(NonEmpty qualifierqualifierArgument, Object value) {
            if (value == null) return When.NEVER;
            if (value instanceof String) {
                return ((String) value).isEmpty()?When.NEVER:When.ALWAYS;
            }
            if (value instanceof Collection) {
                return ((Collection) value).isEmpty()?When.NEVER:When.ALWAYS;
            }
            return When.NEVER;
        }
    }
}
