'use client';

import { OrgProvider } from '@components/Contexts/OrgContext'
import ErrorUI from '@components/Objects/StyledElements/Error/Error'
import { useSearchParams } from 'next/navigation'
import React from 'react'

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode
}) {
    // Use optional chaining with proper typing to fix build error
    const searchParams = useSearchParams()
    // Type-safe approach to getting optional params
    const orgslug = searchParams ? searchParams.get('orgslug') : null
    
    if (orgslug) {
        return <OrgProvider orgslug={orgslug}>{children}</OrgProvider>
    } else {
        return <ErrorUI message='Organization not specified' submessage='Please access this page from an Organization' />
    }
}