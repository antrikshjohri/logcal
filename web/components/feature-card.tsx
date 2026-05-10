import {
  Camera,
  Flame,
  History,
  LayoutDashboard,
  Mic,
  Sparkles,
  type LucideIcon
} from "lucide-react";

const FEATURE_ICONS = {
  spark: Sparkles,
  mic: Mic,
  camera: Camera,
  chart: LayoutDashboard,
  history: History,
  flame: Flame
} as const satisfies Record<string, LucideIcon>;

export type FeatureIconKey = keyof typeof FEATURE_ICONS;

export type FeatureCardProps = {
  icon: FeatureIconKey;
  title: string;
  description: string;
};

/**
 * Homepage feature tile: Lucide icons for crisp, consistent strokes.
 */
export function FeatureCard({ icon, title, description }: FeatureCardProps) {
  const LucideGlyph = FEATURE_ICONS[icon];
  return (
    <article className="feature-card feature-card-coded">
      <div className="feature-card-coded-icon-wrap" aria-hidden="true">
        <LucideGlyph className="feature-card-coded-lucide" strokeWidth={1.75} />
      </div>
      <h3>{title}</h3>
      <span className="feature-card-coded-rule" aria-hidden="true" />
      <p>{description}</p>
    </article>
  );
}
