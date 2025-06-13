import React from 'react'
import Image from 'next/image'

interface SafeAvatarProps {
  src?: string
  alt: string
  size?: number
  className?: string
}

/**
 * SafeAvatar component that ensures correct domain for avatar images
 */
const SafeAvatar: React.FC<SafeAvatarProps> = ({ 
  src, 
  alt, 
  size = 40, 
  className 
}) => {
  // Default empty avatar path that uses relative URL (domain-safe)
  const defaultAvatarSrc = '/images/empty_avatar.png'
  
  // Handle potentially cross-domain avatar URLs
  const sanitizedSrc = React.useMemo(() => {
    if (!src) return defaultAvatarSrc
    
    try {
      // Check if the URL has a domain
      const url = new URL(src, window.location.origin)
      
      // If the URL is from a different domain, use the default avatar
      if (url.hostname !== window.location.hostname) {
        console.warn(`[SafeAvatar] Detected cross-domain avatar: ${src}`)
        return defaultAvatarSrc
      }
      
      return src
    } catch (e) {
      // If parsing fails, just use the src as is (could be a relative path)
      return src
    }
  }, [src])
  
  return (
    <Image
      src={sanitizedSrc}
      alt={alt}
      width={size}
      height={size}
      className={className}
      onError={(e) => {
        // If image fails to load, fallback to default
        const target = e.target as HTMLImageElement
        target.src = defaultAvatarSrc
      }}
    />
  )
}

export default SafeAvatar