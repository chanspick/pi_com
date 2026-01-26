"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

interface RadioGroupProps {
  value?: string;
  onValueChange?: (value: string) => void;
  className?: string;
  children: React.ReactNode;
}

const RadioGroupContext = React.createContext<{
  value?: string;
  onValueChange?: (value: string) => void;
}>({});

const RadioGroup = React.forwardRef<HTMLDivElement, RadioGroupProps>(
  ({ value, onValueChange, className, children, ...props }, ref) => {
    return (
      <RadioGroupContext.Provider value={{ value, onValueChange }}>
        <div
          ref={ref}
          role="radiogroup"
          className={cn("grid gap-3", className)}
          {...props}
        >
          {children}
        </div>
      </RadioGroupContext.Provider>
    );
  }
);
RadioGroup.displayName = "RadioGroup";

interface RadioGroupItemProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  value: string;
}

const RadioGroupItem = React.forwardRef<HTMLInputElement, RadioGroupItemProps>(
  ({ className, value, children, ...props }, ref) => {
    const context = React.useContext(RadioGroupContext);
    const isChecked = context.value === value;

    return (
      <label
        className={cn(
          "flex items-center space-x-3 cursor-pointer p-4 rounded-lg border-2 transition-colors",
          isChecked
            ? "border-blue-600 bg-blue-50"
            : "border-gray-200 hover:border-blue-300",
          className
        )}
      >
        <input
          type="radio"
          ref={ref}
          className="sr-only"
          value={value}
          checked={isChecked}
          onChange={() => context.onValueChange?.(value)}
          {...props}
        />
        <div
          className={cn(
            "h-5 w-5 rounded-full border-2 flex items-center justify-center",
            isChecked ? "border-blue-600" : "border-gray-400"
          )}
        >
          {isChecked && (
            <div className="h-2.5 w-2.5 rounded-full bg-blue-600" />
          )}
        </div>
        <div className="flex-1">{children}</div>
      </label>
    );
  }
);
RadioGroupItem.displayName = "RadioGroupItem";

export { RadioGroup, RadioGroupItem };
