package com.flotechnologies.annotations;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

import javax.annotation.meta.TypeQualifier;
import javax.annotation.meta.TypeQualifierValidator;
import javax.annotation.meta.When;

@Documented
@TypeQualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface NonBlank {
    When when() default When.ALWAYS;

    public static class Checker implements TypeQualifierValidator<NonBlank> {
        public Checker() {
        }

        @Override
        public When forConstantValue(NonBlank qualifierqualifierArgument, Object value) {
            if (value == null) return When.NEVER;
            if (value instanceof String) {
                return ((String) value).trim().isEmpty()?When.NEVER:When.ALWAYS;
            }
            return When.NEVER;
        }
    }
}
