import React from "react";
import { cn } from "../utils/cn";

interface IconProps {
  name: string;
  className?: string;
  style?: React.CSSProperties;
  id?: string;
}

export function Icon({ name, className, style, id }: IconProps) {
  return (
    <span
      className={cn("shrink-0", name, className)}
      style={style}
      aria-hidden="true"
      id={id}
    />
  );
}
