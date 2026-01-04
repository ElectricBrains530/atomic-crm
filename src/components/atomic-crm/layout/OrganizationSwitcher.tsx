import { Button } from "@/components/ui/button";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Building, Check } from "lucide-react";
import { useGetIdentity } from "ra-core";

import { setActiveOrgId } from "../providers/supabase/activeOrg";

export const OrganizationSwitcher = () => {
    const { data: identity, isLoading } = useGetIdentity();

    if (isLoading || !identity?.availableOrgs) return null;

    const currentOrg = identity.availableOrgs.find(
        (o: any) => o.id === identity.activeOrgId
    );

    const handleSwitch = (orgId: number) => {
        if (orgId === identity.activeOrgId) return;
        setActiveOrgId(orgId);
        // Hard reload to ensure all data providers and hooks reset with new context
        window.location.reload();
    };

    return (
        <DropdownMenu>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm" className="gap-2 px-2">
                    <Building className="h-4 w-4" />
                    <span className="hidden md:inline-block">
                        {currentOrg?.descriptor || currentOrg?.name || "Organization"}
                    </span>
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
                <DropdownMenuLabel>Switch Organization</DropdownMenuLabel>
                <DropdownMenuSeparator />
                {identity.availableOrgs.map((org: any) => (
                    <DropdownMenuItem
                        key={org.id}
                        onClick={() => handleSwitch(org.id)}
                        className="gap-2 justify-between"
                    >
                        {org.descriptor || org.name}
                        {org.id === identity.activeOrgId && (
                            <Check className="h-4 w-4 opacity-50" />
                        )}
                    </DropdownMenuItem>
                ))}
            </DropdownMenuContent>
        </DropdownMenu>
    );
};
