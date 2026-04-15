import React, { PropsWithChildren } from "react";

export function Badge({ children, ...rest }: PropsWithChildren) {
  return (
    <span
      className="shrink-0 inline-flex items-center px-2 py-1 font-sans font-normal text-sm truncate bg-ltrn-lightest text-ltrn-dark"
      {...rest}
    >
      {children}
    </span>
  );
}
