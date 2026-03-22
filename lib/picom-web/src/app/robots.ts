import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/my/", "/checkout/", "/sell/", "/admin/"] },
    sitemap: "https://picom.team/sitemap.xml",
  };
}
